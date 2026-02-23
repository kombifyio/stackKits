/**
 * Evaluation Service
 *
 * Implements the evaluation state machine from old admin's evaluation_service.go.
 * Handles state transitions, history tracking, and workflow validation.
 *
 * State Machine:
 *   PENDING → IN_PROGRESS → NEEDS_REVIEW → COMPLETED
 *                ↓              ↓
 *          NEEDS_REVISION ←─────┘
 *                ↓
 *          IN_PROGRESS (retry)
 *
 * Usage:
 *   import { EvaluationService } from './evaluation-service';
 *   const svc = new EvaluationService(prisma);
 *   await svc.startEvaluation(toolId, { evaluatedBy: 'agent' });
 *   await svc.submitForReview(evaluationId, scores);
 *   await svc.approve(evaluationId, 'reviewer');
 */

import {
  PrismaClient,
  Tool,
  ToolEvaluation,
  EvaluationState,
  EvaluationVerdict,
} from '@prisma/client';

/**
 * Valid state transitions in the evaluation workflow.
 */
const VALID_TRANSITIONS: Record<EvaluationState, EvaluationState[]> = {
  PENDING: ['IN_PROGRESS'],
  IN_PROGRESS: ['NEEDS_REVIEW', 'PENDING'],
  NEEDS_REVIEW: ['COMPLETED', 'NEEDS_REVISION'],
  NEEDS_REVISION: ['IN_PROGRESS'],
  COMPLETED: [], // Terminal state
};

/**
 * History entry stored in Tool.evaluationHistory
 */
interface EvaluationHistoryEntry {
  evaluationId: string;
  state: EvaluationState;
  changedAt: string;
  changedBy: string;
  verdict?: EvaluationVerdict;
  comment?: string;
}

/**
 * Input for starting an evaluation
 */
export interface StartEvaluationInput {
  evaluatedBy: string;
  evaluatedVersion?: string;
  n8nExecutionId?: string;
}

/**
 * Input for submitting evaluation scores
 */
export interface SubmitEvaluationInput {
  verdict: EvaluationVerdict;
  scoreDocumentation?: number;
  scoreCommunity?: number;
  scoreDocker?: number;
  scoreSecurity?: number;
  scoreIntegration?: number;
  scoreResources?: number;
  scoreApi?: number;
  strengths?: string[];
  weaknesses?: string[];
  integrationNotes?: string;
  compatibilityNotes?: string;
  notes?: string;
}

export class EvaluationService {
  constructor(private readonly prisma: PrismaClient) {}

  /**
   * Start a new evaluation for a tool.
   * Creates evaluation in PENDING state, then transitions to IN_PROGRESS.
   */
  async startEvaluation(toolId: string, input: StartEvaluationInput): Promise<ToolEvaluation> {
    // Check tool exists
    const tool = await this.prisma.tool.findUnique({ where: { id: toolId } });
    if (!tool) {
      throw new Error(`Tool not found: ${toolId}`);
    }

    // Create evaluation in PENDING state
    const evaluation = await this.prisma.toolEvaluation.create({
      data: {
        toolId,
        evaluatedBy: input.evaluatedBy,
        evaluatedVersion: input.evaluatedVersion,
        n8nExecutionId: input.n8nExecutionId,
        verdict: EvaluationVerdict.DEFERRED, // Default until scored
        state: EvaluationState.PENDING,
      },
    });

    // Log history
    await this.logHistory(tool, evaluation.id, EvaluationState.PENDING, input.evaluatedBy, 'Evaluation started');

    // Transition to IN_PROGRESS
    return this.transitionState(evaluation.id, EvaluationState.IN_PROGRESS, input.evaluatedBy);
  }

  /**
   * Submit evaluation scores and move to NEEDS_REVIEW state.
   */
  async submitForReview(evaluationId: string, input: SubmitEvaluationInput, reviewer: string): Promise<ToolEvaluation> {
    const evaluation = await this.prisma.toolEvaluation.findUnique({
      where: { id: evaluationId },
      include: { tool: true },
    });

    if (!evaluation) {
      throw new Error(`Evaluation not found: ${evaluationId}`);
    }

    if (evaluation.state !== EvaluationState.IN_PROGRESS) {
      throw new Error(`Cannot submit: evaluation is in ${evaluation.state} state`);
    }

    // Calculate overall score (weighted average)
    const scores = [
      input.scoreDocumentation,
      input.scoreCommunity,
      input.scoreDocker,
      input.scoreSecurity,
      input.scoreIntegration,
      input.scoreResources,
      input.scoreApi,
    ].filter((s): s is number => s !== undefined && s !== null);

    const overallScore = scores.length > 0
      ? Math.round(scores.reduce((a, b) => a + b, 0) / scores.length)
      : null;

    // Update evaluation with scores
    const updated = await this.prisma.toolEvaluation.update({
      where: { id: evaluationId },
      data: {
        verdict: input.verdict,
        scoreDocumentation: input.scoreDocumentation,
        scoreCommunity: input.scoreCommunity,
        scoreDocker: input.scoreDocker,
        scoreSecurity: input.scoreSecurity,
        scoreIntegration: input.scoreIntegration,
        scoreResources: input.scoreResources,
        scoreApi: input.scoreApi,
        overallScore,
        strengths: input.strengths || [],
        weaknesses: input.weaknesses || [],
        integrationNotes: input.integrationNotes,
        compatibilityNotes: input.compatibilityNotes,
        notes: input.notes,
        state: EvaluationState.NEEDS_REVIEW,
        previousState: evaluation.state,
        stateChangedAt: new Date(),
      },
    });

    await this.logHistory(evaluation.tool, evaluationId, EvaluationState.NEEDS_REVIEW, reviewer, 'Submitted for review', input.verdict);

    return updated;
  }

  /**
   * Approve an evaluation (move to COMPLETED).
   */
  async approve(evaluationId: string, reviewer: string, feedback?: string): Promise<ToolEvaluation> {
    const evaluation = await this.prisma.toolEvaluation.findUnique({
      where: { id: evaluationId },
      include: { tool: true },
    });

    if (!evaluation) {
      throw new Error(`Evaluation not found: ${evaluationId}`);
    }

    if (evaluation.state !== EvaluationState.NEEDS_REVIEW) {
      throw new Error(`Cannot approve: evaluation is in ${evaluation.state} state`);
    }

    const updated = await this.prisma.toolEvaluation.update({
      where: { id: evaluationId },
      data: {
        state: EvaluationState.COMPLETED,
        previousState: evaluation.state,
        stateChangedAt: new Date(),
        reviewerFeedback: feedback,
      },
    });

    await this.logHistory(evaluation.tool, evaluationId, EvaluationState.COMPLETED, reviewer, feedback || 'Approved');

    return updated;
  }

  /**
   * Request revision (move to NEEDS_REVISION).
   */
  async requestRevision(evaluationId: string, reviewer: string, feedback: string): Promise<ToolEvaluation> {
    const evaluation = await this.prisma.toolEvaluation.findUnique({
      where: { id: evaluationId },
      include: { tool: true },
    });

    if (!evaluation) {
      throw new Error(`Evaluation not found: ${evaluationId}`);
    }

    if (evaluation.state !== EvaluationState.NEEDS_REVIEW) {
      throw new Error(`Cannot request revision: evaluation is in ${evaluation.state} state`);
    }

    const updated = await this.prisma.toolEvaluation.update({
      where: { id: evaluationId },
      data: {
        state: EvaluationState.NEEDS_REVISION,
        previousState: evaluation.state,
        stateChangedAt: new Date(),
        reviewerFeedback: feedback,
        revisionNumber: { increment: 1 },
      },
    });

    await this.logHistory(evaluation.tool, evaluationId, EvaluationState.NEEDS_REVISION, reviewer, feedback);

    return updated;
  }

  /**
   * Restart evaluation after revision feedback (move to IN_PROGRESS).
   */
  async restartAfterRevision(evaluationId: string, evaluator: string): Promise<ToolEvaluation> {
    const evaluation = await this.prisma.toolEvaluation.findUnique({
      where: { id: evaluationId },
      include: { tool: true },
    });

    if (!evaluation) {
      throw new Error(`Evaluation not found: ${evaluationId}`);
    }

    if (evaluation.state !== EvaluationState.NEEDS_REVISION) {
      throw new Error(`Cannot restart: evaluation is in ${evaluation.state} state`);
    }

    const updated = await this.prisma.toolEvaluation.update({
      where: { id: evaluationId },
      data: {
        state: EvaluationState.IN_PROGRESS,
        previousState: evaluation.state,
        stateChangedAt: new Date(),
      },
    });

    await this.logHistory(evaluation.tool, evaluationId, EvaluationState.IN_PROGRESS, evaluator, `Revision ${evaluation.revisionNumber + 1} started`);

    return updated;
  }

  /**
   * Generic state transition with validation.
   */
  async transitionState(evaluationId: string, newState: EvaluationState, changedBy: string): Promise<ToolEvaluation> {
    const evaluation = await this.prisma.toolEvaluation.findUnique({
      where: { id: evaluationId },
      include: { tool: true },
    });

    if (!evaluation) {
      throw new Error(`Evaluation not found: ${evaluationId}`);
    }

    // Validate transition
    const validStates = VALID_TRANSITIONS[evaluation.state];
    if (!validStates.includes(newState)) {
      throw new Error(`Invalid state transition: ${evaluation.state} → ${newState}`);
    }

    const updated = await this.prisma.toolEvaluation.update({
      where: { id: evaluationId },
      data: {
        state: newState,
        previousState: evaluation.state,
        stateChangedAt: new Date(),
      },
    });

    await this.logHistory(evaluation.tool, evaluationId, newState, changedBy);

    return updated;
  }

  /**
   * Get evaluations by state.
   */
  async getByState(state: EvaluationState): Promise<ToolEvaluation[]> {
    return this.prisma.toolEvaluation.findMany({
      where: { state },
      include: { tool: true },
      orderBy: { evaluatedAt: 'desc' },
    });
  }

  /**
   * Get evaluation history for a tool.
   */
  async getHistory(toolId: string): Promise<EvaluationHistoryEntry[]> {
    const tool = await this.prisma.tool.findUnique({
      where: { id: toolId },
      select: { evaluationHistory: true },
    });

    if (!tool?.evaluationHistory) {
      return [];
    }

    return tool.evaluationHistory as unknown as EvaluationHistoryEntry[];
  }

  /**
   * Log evaluation state change to tool's history.
   */
  private async logHistory(
    tool: Tool,
    evaluationId: string,
    state: EvaluationState,
    changedBy: string,
    comment?: string,
    verdict?: EvaluationVerdict
  ): Promise<void> {
    const entry: EvaluationHistoryEntry = {
      evaluationId,
      state,
      changedAt: new Date().toISOString(),
      changedBy,
      verdict,
      comment,
    };

    const history = (tool.evaluationHistory as unknown as EvaluationHistoryEntry[]) || [];
    history.push(entry);

    // Keep last 50 entries
    const trimmedHistory = history.slice(-50);

    await this.prisma.tool.update({
      where: { id: tool.id },
      data: {
        evaluationHistory: trimmedHistory as unknown as any,
      },
    });
  }
}

/**
 * Create a singleton instance for use in scripts
 */
export function createEvaluationService(prisma: PrismaClient): EvaluationService {
  return new EvaluationService(prisma);
}
