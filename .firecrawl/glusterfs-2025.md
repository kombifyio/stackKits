[Sitemap](https://medium.com/sitemap/sitemap.xml)

[Open in app](https://play.google.com/store/apps/details?id=com.medium.reader&referrer=utm_source%3DmobileNavBar&source=post_page---top_nav_layout_nav-----------------------------------------)

Sign up

[Sign in](https://medium.com/m/signin?operation=login&redirect=https%3A%2F%2Fmedium.com%2F%40vigneshvar.a.s%2Fwhy-im-still-running-glusterfs-in-2025-and-you-might-want-to-9e81121a8f9b&source=post_page---top_nav_layout_nav-----------------------global_nav------------------)

[Medium Logo](https://medium.com/?source=post_page---top_nav_layout_nav-----------------------------------------)

[Write](https://medium.com/m/signin?operation=register&redirect=https%3A%2F%2Fmedium.com%2Fnew-story&source=---top_nav_layout_nav-----------------------new_post_topnav------------------)

[Search](https://medium.com/search?source=post_page---top_nav_layout_nav-----------------------------------------)

Sign up

[Sign in](https://medium.com/m/signin?operation=login&redirect=https%3A%2F%2Fmedium.com%2F%40vigneshvar.a.s%2Fwhy-im-still-running-glusterfs-in-2025-and-you-might-want-to-9e81121a8f9b&source=post_page---top_nav_layout_nav-----------------------global_nav------------------)

![](https://miro.medium.com/v2/resize:fill:32:32/1*dmbNkD5D-u45r44go_cf0g.png)

Member-only story

# Why I’m Still Running GlusterFS in 2025 (And You Might Want To)

## A Complete Guide to Installing GlusterFS on Ubuntu: Simple Distributed Storage for Small Clusters Without the Ceph Complexity

[![Vigneshvar A S](https://miro.medium.com/v2/resize:fill:32:32/1*02Swxg4ugpSHY9iUxIvFiQ.jpeg)](https://medium.com/@vigneshvar.a.s?source=post_page---byline--9e81121a8f9b---------------------------------------)

[Vigneshvar A S](https://medium.com/@vigneshvar.a.s?source=post_page---byline--9e81121a8f9b---------------------------------------)

Follow

9 min read

·

Dec 24, 2025

3

[Listen](https://medium.com/m/signin?actionUrl=https%3A%2F%2Fmedium.com%2Fplans%3Fdimension%3Dpost_audio_button%26postId%3D9e81121a8f9b&operation=register&redirect=https%3A%2F%2Fmedium.com%2F%40vigneshvar.a.s%2Fwhy-im-still-running-glusterfs-in-2025-and-you-might-want-to-9e81121a8f9b&source=---header_actions--9e81121a8f9b---------------------post_audio_button------------------)

Share

**🚀 TL;DR:**

- Red Hat Gluster Storage EOL December 2024, but open-source project still active
- Complete installation guide for Ubuntu 22.04 (under 20 minutes)
- Replicated volumes, volume mounting, troubleshooting included
- Real benchmarks: 250 MB/s write, 280 MB/s read on consumer SSDs
- Perfect for: 2–10 nodes, Docker volumes, backups, home labs
- Why I chose it over Ceph for my 3-node cluster
- Three weeks running: zero downtime, automatic failure recovery

**Not a Medium member?** You can read this story for **free** [**_here_**](https://medium.com/@vigneshvar.a.s/why-im-still-running-glusterfs-in-2025-and-you-might-want-to-9e81121a8f9b?sk=3edbc8b5a3579409e24b8f8c85e18ac2)

GlusterFS installation on Ubuntu provides reliable distributed storage even in 2025. You’ve probably heard the news. Red Hat ended commercial support for Gluster Storage at the end of 2024. The tech forums are buzzing with “GlusterFS is dead” posts. Everyone’s migrating to Ceph or other solutions.

So why am I writing a blog post about setting up GlusterFS ?

Because sometimes the “old” technology is exactly what you need. Let me tell you a story.

Press enter or click to view image in full size

![](https://miro.medium.com/v2/resize:fit:700/1*s17QQtunWRi7p6xjO6_aBg.png)

GlusterFS volume status showing healthy 3-node replicated cluster on Ubuntu 22.04

### The Three-Day Detour

Last month, I needed shared storage for a small cluster of three servers. Like any good engineer, I went with the “industry standard” approach — **_Ceph_**.

**Day one:**

Reading documentation about MONs, OSDs, and placement groups.

**Day two:**

Trying to understand why my consumer-grade SSDs weren’t cutting it.

**Day three:**

Staring at error logs at 2 AM, questioning my life choices.

Don’t get me wrong — **_Ceph_** is brilliant technology. For a 50-node cluster with enterprise hardware, it’s probably perfect. For my three refurbished Dell servers sitting in a closet? It was like using my Jaguar to commute to the grocery store.

## Create an account to read the full story.

The author made this story available to Medium members only.

If you’re new to Medium, create a new account to read this story on us.

[Continue in app](https://play.google.com/store/apps/details?id=com.medium.reader&referrer=utm_source%3Dregwall&source=-----9e81121a8f9b---------------------post_regwall------------------)

Or, continue in mobile web

[Sign up with Google](https://medium.com/m/connect/google?state=google-%7Chttps%3A%2F%2Fmedium.com%2F%40vigneshvar.a.s%2Fwhy-im-still-running-glusterfs-in-2025-and-you-might-want-to-9e81121a8f9b%3Fsource%3D-----9e81121a8f9b---------------------post_regwall------------------%26skipOnboarding%3D1%7Cregister&source=-----9e81121a8f9b---------------------post_regwall------------------)

[Sign up with Facebook](https://medium.com/m/connect/facebook?state=facebook-%7Chttps%3A%2F%2Fmedium.com%2F%40vigneshvar.a.s%2Fwhy-im-still-running-glusterfs-in-2025-and-you-might-want-to-9e81121a8f9b%3Fsource%3D-----9e81121a8f9b---------------------post_regwall------------------%26skipOnboarding%3D1%7Cregister&source=-----9e81121a8f9b---------------------post_regwall------------------)

Sign up with email

Already have an account? [Sign in](https://medium.com/m/signin?operation=login&redirect=https%3A%2F%2Fmedium.com%2F%40vigneshvar.a.s%2Fwhy-im-still-running-glusterfs-in-2025-and-you-might-want-to-9e81121a8f9b&source=-----9e81121a8f9b---------------------post_regwall------------------)

3

3

[![Vigneshvar A S](https://miro.medium.com/v2/resize:fill:48:48/1*02Swxg4ugpSHY9iUxIvFiQ.jpeg)](https://medium.com/@vigneshvar.a.s?source=post_page---post_author_info--9e81121a8f9b---------------------------------------)

[![Vigneshvar A S](https://miro.medium.com/v2/resize:fill:64:64/1*02Swxg4ugpSHY9iUxIvFiQ.jpeg)](https://medium.com/@vigneshvar.a.s?source=post_page---post_author_info--9e81121a8f9b---------------------------------------)

Follow

[**Written by Vigneshvar A S**](https://medium.com/@vigneshvar.a.s?source=post_page---post_author_info--9e81121a8f9b---------------------------------------)

[34 followers](https://medium.com/@vigneshvar.a.s/followers?source=post_page---post_author_info--9e81121a8f9b---------------------------------------)

· [33 following](https://medium.com/@vigneshvar.a.s/following?source=post_page---post_author_info--9e81121a8f9b---------------------------------------)

Follow

## No responses yet

![](https://miro.medium.com/v2/resize:fill:32:32/1*dmbNkD5D-u45r44go_cf0g.png)

Write a response

[What are your thoughts?](https://medium.com/m/signin?operation=register&redirect=https%3A%2F%2Fmedium.com%2F%40vigneshvar.a.s%2Fwhy-im-still-running-glusterfs-in-2025-and-you-might-want-to-9e81121a8f9b&source=---post_responses--9e81121a8f9b---------------------respond_sidebar------------------)

Cancel

Respond

## More from Vigneshvar A S

![Redis Cluster Internals: What Actually Happens During Failover](https://miro.medium.com/v2/resize:fit:679/format:webp/1*YQRI9C-XUGjajbBDcBbbFg.png)

[![Vigneshvar A S](https://miro.medium.com/v2/resize:fill:20:20/1*02Swxg4ugpSHY9iUxIvFiQ.jpeg)](https://medium.com/@vigneshvar.a.s?source=post_page---author_recirc--9e81121a8f9b----0---------------------30f86a5b_57a2_4232_84f7_3c658c7c7f14--------------)

[Vigneshvar A S](https://medium.com/@vigneshvar.a.s?source=post_page---author_recirc--9e81121a8f9b----0---------------------30f86a5b_57a2_4232_84f7_3c658c7c7f14--------------)

[**Redis Cluster Internals: What Actually Happens During Failover**\\
\\
**How Redis Handles High Load: Architecture Secrets That Keep It Stable**](https://medium.com/@vigneshvar.a.s/redis-cluster-internals-what-actually-happens-during-failover-3f9a8b59ed26?source=post_page---author_recirc--9e81121a8f9b----0---------------------30f86a5b_57a2_4232_84f7_3c658c7c7f14--------------)

Jan 11

[A clap icon5](https://medium.com/@vigneshvar.a.s/redis-cluster-internals-what-actually-happens-during-failover-3f9a8b59ed26?source=post_page---author_recirc--9e81121a8f9b----0---------------------30f86a5b_57a2_4232_84f7_3c658c7c7f14--------------)

![The 3 AM Wake-Up Call That Made Me Build a Slack Bot](https://miro.medium.com/v2/resize:fit:679/format:webp/1*9JxIio8t4WZekLaeTSJNvg.png)

[![Vigneshvar A S](https://miro.medium.com/v2/resize:fill:20:20/1*02Swxg4ugpSHY9iUxIvFiQ.jpeg)](https://medium.com/@vigneshvar.a.s?source=post_page---author_recirc--9e81121a8f9b----1---------------------30f86a5b_57a2_4232_84f7_3c658c7c7f14--------------)

[Vigneshvar A S](https://medium.com/@vigneshvar.a.s?source=post_page---author_recirc--9e81121a8f9b----1---------------------30f86a5b_57a2_4232_84f7_3c658c7c7f14--------------)

[**The 3 AM Wake-Up Call That Made Me Build a Slack Bot**\\
\\
**It was 3:47 AM when my phone buzzed.  Another alert….**](https://medium.com/@vigneshvar.a.s/the-3-am-wake-up-call-that-made-me-build-a-slack-bot-406eb4a2e884?source=post_page---author_recirc--9e81121a8f9b----1---------------------30f86a5b_57a2_4232_84f7_3c658c7c7f14--------------)

Dec 23, 2025

[A clap icon3](https://medium.com/@vigneshvar.a.s/the-3-am-wake-up-call-that-made-me-build-a-slack-bot-406eb4a2e884?source=post_page---author_recirc--9e81121a8f9b----1---------------------30f86a5b_57a2_4232_84f7_3c658c7c7f14--------------)

![Why Most AI Systems Fail in Production (Even With any GPTs or RAG)](https://miro.medium.com/v2/resize:fit:679/format:webp/1*CktEvketdx43aoIG18WiIg.jpeg)

[![Vigneshvar A S](https://miro.medium.com/v2/resize:fill:20:20/1*02Swxg4ugpSHY9iUxIvFiQ.jpeg)](https://medium.com/@vigneshvar.a.s?source=post_page---author_recirc--9e81121a8f9b----2---------------------30f86a5b_57a2_4232_84f7_3c658c7c7f14--------------)

[Vigneshvar A S](https://medium.com/@vigneshvar.a.s?source=post_page---author_recirc--9e81121a8f9b----2---------------------30f86a5b_57a2_4232_84f7_3c658c7c7f14--------------)

[**Why Most AI Systems Fail in Production (Even With any GPTs or RAG)**\\
\\
**A practical guide to LLM hallucinations, reasoning limits, RAG pitfalls, and building reliable AI systems in production**](https://medium.com/@vigneshvar.a.s/why-most-ai-systems-fail-in-production-even-with-any-gpts-or-rag-2438923878af?source=post_page---author_recirc--9e81121a8f9b----2---------------------30f86a5b_57a2_4232_84f7_3c658c7c7f14--------------)

Dec 18, 2025

[A clap icon65](https://medium.com/@vigneshvar.a.s/why-most-ai-systems-fail-in-production-even-with-any-gpts-or-rag-2438923878af?source=post_page---author_recirc--9e81121a8f9b----2---------------------30f86a5b_57a2_4232_84f7_3c658c7c7f14--------------)

![Running GlusterFS in Kubernetes Without Privileged Containers: A Security Team’s Dream](https://miro.medium.com/v2/resize:fit:679/format:webp/1*Tu9Bk8UtIkfHFT6ihEDLGA.png)

[![Vigneshvar A S](https://miro.medium.com/v2/resize:fill:20:20/1*02Swxg4ugpSHY9iUxIvFiQ.jpeg)](https://medium.com/@vigneshvar.a.s?source=post_page---author_recirc--9e81121a8f9b----3---------------------30f86a5b_57a2_4232_84f7_3c658c7c7f14--------------)

[Vigneshvar A S](https://medium.com/@vigneshvar.a.s?source=post_page---author_recirc--9e81121a8f9b----3---------------------30f86a5b_57a2_4232_84f7_3c658c7c7f14--------------)

[**Running GlusterFS in Kubernetes Without Privileged Containers: A Security Team’s Dream**\\
\\
**How to Deploy GlusterFS on Kubernetes Without Privileged Mode or CAP\_SYS\_ADMIN Using User Namespace Extended Attributes — A Step-by-Step…**](https://medium.com/@vigneshvar.a.s/running-glusterfs-in-kubernetes-without-privileged-containers-a-security-teams-dream-ea872c4d8624?source=post_page---author_recirc--9e81121a8f9b----3---------------------30f86a5b_57a2_4232_84f7_3c658c7c7f14--------------)

Dec 25, 2025

[A clap icon22](https://medium.com/@vigneshvar.a.s/running-glusterfs-in-kubernetes-without-privileged-containers-a-security-teams-dream-ea872c4d8624?source=post_page---author_recirc--9e81121a8f9b----3---------------------30f86a5b_57a2_4232_84f7_3c658c7c7f14--------------)

[See all from Vigneshvar A S](https://medium.com/@vigneshvar.a.s?source=post_page---author_recirc--9e81121a8f9b---------------------------------------)

## Recommended from Medium

![How to Build a Secure Linux Server](https://miro.medium.com/v2/resize:fit:679/format:webp/1*EInqfRUV9SEEBWo7QNKHbQ.png)

[![System Weakness](https://miro.medium.com/v2/resize:fill:20:20/1*gncXIKhx5QOIX0K9MGcVkg.jpeg)](https://medium.com/system-weakness?source=post_page---read_next_recirc--9e81121a8f9b----0---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

In

[System Weakness](https://medium.com/system-weakness?source=post_page---read_next_recirc--9e81121a8f9b----0---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

by

[bektiaw](https://medium.com/@bektiaw?source=post_page---read_next_recirc--9e81121a8f9b----0---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

[**How to Build a Secure Linux Server**\\
\\
**Get the basics right! And you’ll have a server that’s more secure than 90% of what’s out there**](https://medium.com/system-weakness/how-to-build-a-secure-linux-server-509021596097?source=post_page---read_next_recirc--9e81121a8f9b----0---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

Jan 24

[A clap icon137\\
\\
A response icon4](https://medium.com/system-weakness/how-to-build-a-secure-linux-server-509021596097?source=post_page---read_next_recirc--9e81121a8f9b----0---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

![Why We are Moving Away from Terraform 2026](https://miro.medium.com/v2/resize:fit:679/format:webp/0*dFoEdj0gHZ8EFKJ9.png)

[![Cloud With Azeem](https://miro.medium.com/v2/resize:fill:20:20/1*oJWwUx75Cf5oGoEfAefJpw.png)](https://medium.com/@cloudwithazeem?source=post_page---read_next_recirc--9e81121a8f9b----1---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

[Cloud With Azeem](https://medium.com/@cloudwithazeem?source=post_page---read_next_recirc--9e81121a8f9b----1---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

[**Why We are Moving Away from Terraform 2026**\\
\\
**We left Terraform in 2026 due to licensing, lock-in, and better IaC alternatives like OpenTofu and Pulumi. Here’s what we learned.**](https://medium.com/@cloudwithazeem/moving-away-from-terraform-76766966bb05?source=post_page---read_next_recirc--9e81121a8f9b----1---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

Aug 24, 2025

[A clap icon213\\
\\
A response icon14](https://medium.com/@cloudwithazeem/moving-away-from-terraform-76766966bb05?source=post_page---read_next_recirc--9e81121a8f9b----1---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

![Stop Watching OpenClaw Install Tutorials — This Is How You Actually Tame It](https://miro.medium.com/v2/resize:fit:679/format:webp/1*cKognCK0VNSBN79Awlwl8g.png)

[![Activated Thinker](https://miro.medium.com/v2/resize:fill:20:20/1*I0dmd2-TIrUdjo5eUTjtvw.png)](https://medium.com/activated-thinker?source=post_page---read_next_recirc--9e81121a8f9b----0---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

In

[Activated Thinker](https://medium.com/activated-thinker?source=post_page---read_next_recirc--9e81121a8f9b----0---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

by

[Shane Collins](https://medium.com/@intellizab?source=post_page---read_next_recirc--9e81121a8f9b----0---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

[**Stop Watching OpenClaw Install Tutorials — This Is How You Actually Tame It**\\
\\
**Everyone can run npm install. Only a few know how to turn this chaotic AI agent into a tireless digital employee**](https://medium.com/activated-thinker/stop-watching-openclaw-install-tutorials-this-is-how-you-actually-tame-it-f3416f5d80bc?source=post_page---read_next_recirc--9e81121a8f9b----0---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

Feb 1

[A clap icon271\\
\\
A response icon3](https://medium.com/activated-thinker/stop-watching-openclaw-install-tutorials-this-is-how-you-actually-tame-it-f3416f5d80bc?source=post_page---read_next_recirc--9e81121a8f9b----0---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

![6 brain images](https://miro.medium.com/v2/resize:fit:679/format:webp/1*Q-mzQNzJSVYkVGgsmHVjfw.png)

[![Write A Catalyst](https://miro.medium.com/v2/resize:fill:20:20/1*KCHN5TM3Ga2PqZHA4hNbaw.png)](https://medium.com/write-a-catalyst?source=post_page---read_next_recirc--9e81121a8f9b----1---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

In

[Write A Catalyst](https://medium.com/write-a-catalyst?source=post_page---read_next_recirc--9e81121a8f9b----1---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

by

[Dr. Patricia Schmidt](https://medium.com/@creatorschmidt?source=post_page---read_next_recirc--9e81121a8f9b----1---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

[**As a Neuroscientist, I Quit These 5 Morning Habits That Destroy Your Brain**\\
\\
**Most people do \#1 within 10 minutes of waking (and it sabotages your entire day)**](https://medium.com/write-a-catalyst/as-a-neuroscientist-i-quit-these-5-morning-habits-that-destroy-your-brain-3efe1f410226?source=post_page---read_next_recirc--9e81121a8f9b----1---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

Jan 14

[A clap icon27K\\
\\
A response icon467](https://medium.com/write-a-catalyst/as-a-neuroscientist-i-quit-these-5-morning-habits-that-destroy-your-brain-3efe1f410226?source=post_page---read_next_recirc--9e81121a8f9b----1---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

![OpenClaw Security: My Complete Hardening Guide for VPS and Docker Deployments](https://miro.medium.com/v2/resize:fit:679/format:webp/1*wlwwb_RBFh0u1YYvaHn3Jg.png)

[![Reza Rezvani](https://miro.medium.com/v2/resize:fill:20:20/1*jDxVaEgUePd76Bw8xJrr2g.png)](https://medium.com/@alirezarezvani?source=post_page---read_next_recirc--9e81121a8f9b----2---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

[Reza Rezvani](https://medium.com/@alirezarezvani?source=post_page---read_next_recirc--9e81121a8f9b----2---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

[**OpenClaw Security: My Complete Hardening Guide for VPS and Docker Deployments**\\
\\
**A practical guide to securing your AI assistant — from first install to production-ready deployment**](https://medium.com/@alirezarezvani/openclaw-security-my-complete-hardening-guide-for-vps-and-docker-deployments-14d754edfc1e?source=post_page---read_next_recirc--9e81121a8f9b----2---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

Feb 2

[A clap icon71\\
\\
A response icon3](https://medium.com/@alirezarezvani/openclaw-security-my-complete-hardening-guide-for-vps-and-docker-deployments-14d754edfc1e?source=post_page---read_next_recirc--9e81121a8f9b----2---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

![10 OpenClaw Use Cases for a Personal AI Assistant](https://miro.medium.com/v2/resize:fit:679/format:webp/1*3ndDUOAYjgw0eylFd-tSYA.jpeg)

[![Balazs Kocsis](https://miro.medium.com/v2/resize:fill:20:20/1*3gWNkRuEKDJFd-MQIwkLBg.jpeg)](https://medium.com/@balazskocsis?source=post_page---read_next_recirc--9e81121a8f9b----3---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

[Balazs Kocsis](https://medium.com/@balazskocsis?source=post_page---read_next_recirc--9e81121a8f9b----3---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

[**10 OpenClaw Use Cases for a Personal AI Assistant**\\
\\
**How are people actually using OpenClaw, and how are they integrating it?**](https://medium.com/@balazskocsis/10-clawdbot-use-cases-for-a-personal-ai-assistant-aae670867a1d?source=post_page---read_next_recirc--9e81121a8f9b----3---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

Jan 27

[A clap icon48\\
\\
A response icon1](https://medium.com/@balazskocsis/10-clawdbot-use-cases-for-a-personal-ai-assistant-aae670867a1d?source=post_page---read_next_recirc--9e81121a8f9b----3---------------------135c670c_e444_4a6f_9130_4b46794ba0ae--------------)

[See more recommendations](https://medium.com/?source=post_page---read_next_recirc--9e81121a8f9b---------------------------------------)

[Help](https://help.medium.com/hc/en-us?source=post_page-----9e81121a8f9b---------------------------------------)

[Status](https://status.medium.com/?source=post_page-----9e81121a8f9b---------------------------------------)

[About](https://medium.com/about?autoplay=1&source=post_page-----9e81121a8f9b---------------------------------------)

[Careers](https://medium.com/jobs-at-medium/work-at-medium-959d1a85284e?source=post_page-----9e81121a8f9b---------------------------------------)

[Press](mailto:pressinquiries@medium.com)

[Blog](https://blog.medium.com/?source=post_page-----9e81121a8f9b---------------------------------------)

[Privacy](https://policy.medium.com/medium-privacy-policy-f03bf92035c9?source=post_page-----9e81121a8f9b---------------------------------------)

[Rules](https://policy.medium.com/medium-rules-30e5502c4eb4?source=post_page-----9e81121a8f9b---------------------------------------)

[Terms](https://policy.medium.com/medium-terms-of-service-9db0094a1e0f?source=post_page-----9e81121a8f9b---------------------------------------)

[Text to speech](https://speechify.com/medium?source=post_page-----9e81121a8f9b---------------------------------------)

reCAPTCHA

Recaptcha requires verification.

[Privacy](https://www.google.com/intl/en/policies/privacy/) \- [Terms](https://www.google.com/intl/en/policies/terms/)

protected by **reCAPTCHA**

[Privacy](https://www.google.com/intl/en/policies/privacy/) \- [Terms](https://www.google.com/intl/en/policies/terms/)