[Skip to main content](https://fossa.com/blog/business-source-license-requirements-provisions-history/#main-content)

[All](https://fossa.com/blog/) [Announcements](https://fossa.com/blog/tag/fossa/) [SBOM](https://fossa.com/blog/tag/sbom/) [Security](https://fossa.com/blog/tag/security/) [Licensing](https://fossa.com/blog/tag/licensing/) [Open Source](https://fossa.com/blog/tag/open-source/) [Press](https://fossa.com/press/)

[Back to blog](https://fossa.com/blog/)

Table of Contents

The Business Source License (BSL) is a middle ground of sorts between open source and end-user licenses. The BSL (also sometimes abbreviated as BUSL) is considered a [source-available license](https://fossa.com/blog/comprehensive-guide-source-available-software-licenses/) in that anyone can view or use the licensed code for internal or testing purposes, but there are limitations on commercial use.

Unlike [open source licenses](https://fossa.com/learn/developers-guide-open-source-software-licenses), the BSL prohibits the licensed code from being used in production — without explicit approval from the licensor.

But, similar to open source licenses, BSL-licensed source code is publicly available, and anyone is free to use, modify, and/or copy it for non-production purposes.

Additionally, after a set period of time, either four years or an earlier period set by the licensor, the BSL automatically converts to an open source license of the licensor's choosing. However, the open source license must be compatible with GPL, and it usually applies only to specific software versions on a rolling basis, based on the date of release.

_Note: Two versions of the BSL have been released: the original 1.0 and the current 1.1. Assume all references in this blog are to the current BSL 1.1 unless otherwise stated._

[![Image](https://fossa.com/_next/image/?url=%2FHeather-ebook-cta.png&w=3840&q=75&dpl=dpl_3MAzs3crP47YPdFT5ResSp7J8k7U)](https://fossa.com/lp/open-source-business-heather-meeker)

## [Link to section](https://fossa.com/blog/business-source-license-requirements-provisions-history/\#business-source-license-requirements) Business Source License Requirements

The Business Source License has provisions in common with both open source and end-user licenses. It also has a few non-standard clauses that are important to understand. Here’s a look at the license’s key requirements, provisions, and exceptions.

### [Link to section](https://fossa.com/blog/business-source-license-requirements-provisions-history/\#required-change-from-bsl-to-open-source-license) Required Change from BSL to Open Source License

Software licensed under the BSL will not stay under the BSL forever. This is because of a provision that requires software under the BSL to convert to an open source license within four years after its release date. This is sometimes called a “springing license.”

It’s important to note that this requirement applies to specific software versions. If you release v1.0 of your software under the BSL on January 1, 2025, v1.0 must convert to a GPL-compatible license by January 1, 2029. But the four-year clock won’t begin for subsequent versions until the “first publicly available distribution of a specific version.”

Within those general constraints, the licensor has the freedom to decide exactly _when_ the license change will happen (“Change Date”) and _what_ the new license will be (“Change License”).

- **Change Date:** The licensor can specify a date for the license change as long as that date is within four years of the software version’s release. If no date is specified, the change will automatically happen four years after the software is released under the BSL
- **Change License:** The Change License must be [GPL v2](https://fossa.com/blog/open-source-software-licenses-101-gpl-v2/) (or later), or a license compatible with GPL

### [Link to section](https://fossa.com/blog/business-source-license-requirements-provisions-history/\#using-bsl-licensed-software-in-production) Using BSL-Licensed Software in Production

The BSL doesn’t allow licensed code to be used in production unless the licensor uses the “Additional Use Grant” mechanism. The Additional Use Grant allows the licensor to identify specific circumstances where licensed code can be used commercially.

The BSL does not define “production” use. Many licensors use Additional Use Grants to clarify the definition or to broaden the rights granted.

For example, Hashicorp’s BSL implementation (which made headlines when the [company announced its change](https://www.hashicorp.com/blog/hashicorp-adopts-business-source-license) from the [Mozilla Public License](https://fossa.com/blog/open-source-software-licenses-101-mozilla-public-license-2-0/)) includes an Additional Use Grant that does allow for production use — except in products that are competitive with Hashicorp’s.

MariaDB, the license author, takes a different approach. Its Additional Use Grant allows commercial use only if “your application uses the Licensed Work with a total of less than three server instances in production.”

In situations where you want to use BSL-licensed code — but your production use case isn’t covered by an Additional Use Grant — the license states that “You must purchase a commercial license from the Licensor, its affiliated entities, or authorized resellers, or you must refrain from using the Licensed Work.”

### [Link to section](https://fossa.com/blog/business-source-license-requirements-provisions-history/\#other-bsl-provisions) Other BSL Provisions

As mentioned, anyone is free to use, redistribute, copy, modify, and create derivative works of BSL-licensed code for non-production purposes. Additionally, you are required to include a copy of the BSL text in any copy or modification of a BSL-licensed work.

## [Link to section](https://fossa.com/blog/business-source-license-requirements-provisions-history/\#business-source-license-history) Business Source License History

In 2016, MariaDB (a cloud database company founded by members of the core MySQL team) released v1.0 of the Business Source License. MariaDB CTO Michael 'Monty' Widenius [explained the rationale](https://www.zdnet.com/article/open-source-its-true-cost-and-where-its-going-awry-by-monty-widenius/) for creating the license in a ZDNet interview a few years prior. Widenius said, in part:

> _“You can get access to all the source. You can use it in any way but the source has a comment that says you can use it freely except in these circumstances when you have to pay… Because you have the code, you know that if the vendor does something stupid, somebody else can give you the support for it. So you get all the benefits of open source except that a small portion of users has to pay. As long as you continue to develop the project, each version still gets a new timeline…”_

In 2017, MariaDB released its first (and to date only) new version of the license, BSL 1.1. The BSL 1.1 was created with input from Heather Meeker (a leading IP attorney and open source licensing expert) and Bruce Perens (co-founder of the Open Source Initiative).

The essence of the two versions is similar, but there were several notable differences, including:

- In v1.1, the “Change License” (e.g. the open source licenses that the BSL eventually converts into) must be GPL compatible. There was no such requirement in v1.0.
- In v1.1, the “Change Date” (e.g. the date on which the BSL converts to an open source license) must be within four years of the software release date. This time constraint didn’t exist in v1.0.
- While v1.0 allowed the licensor to specify situations where the licensed software could not be used (“Usage Limitation”), v1.1 takes the opposite approach. It introduces “Additional Use Grants,” which the licensor can use to communicate circumstances where the licensed code can be used in production.

## [Link to section](https://fossa.com/blog/business-source-license-requirements-provisions-history/\#additional-software-licensing-resources) Additional Software Licensing Resources

For more information on software licensing, consider checking out the following articles from leading IP attorney Heather Meeker:

- [Heather Meeker on the AGPL](https://fossa.com/blog/oss-license-compliance-expert-heather-meeker-agpl/): Heather analyzes the [AGPL](https://fossa.com/blog/open-source-software-licenses-101-agpl-license/) (a network [copyleft license](https://fossa.com/blog/all-about-copyleft-licenses/)), including its source code disclosure provision
- [Heather Meeker on Open Source License Notices and Automation](https://fossa.com/blog/heather-meeker-open-source-license-notices-automation/): Heather discusses open source license notices (including how they differ from copyright notices) and the role of automation in simplifying notice creation
- [Heather Meeker on Open Source License Compliance Tools](https://fossa.com/blog/heather-meeker-open-source-license-compliance-tools/): Heather shares guidance on evaluating license compliance technologies and strategies for getting more value from existing tools

## [Link to section](https://fossa.com/blog/business-source-license-requirements-provisions-history/\#frequently-asked-questions-about-the-business-source-license) Frequently Asked Questions About the Business Source License

### [Link to section](https://fossa.com/blog/business-source-license-requirements-provisions-history/\#what-is-the-business-source-license-bsl) What is the Business Source License (BSL)?

The Business Source License (BSL) is a source-available license that sits between open source and proprietary licenses. It allows anyone to view, use, modify, and copy the code for non-production purposes, but restricts commercial production use unless explicitly granted by the licensor.

### [Link to section](https://fossa.com/blog/business-source-license-requirements-provisions-history/\#is-the-business-source-license-an-open-source-license) Is the Business Source License an open source license?

No, the BSL is not considered an open source license because it restricts production use. However, it automatically converts to a GPL-compatible open source license after a set period (typically within four years), making it a "source-available" license with a "springing license" provision.

### [Link to section](https://fossa.com/blog/business-source-license-requirements-provisions-history/\#what-are-the-requirements-of-the-business-source-license) What are the requirements of the Business Source License?

The BSL requires that you include a copy of the license text in any copy or modification of the licensed work. For non-production use, you can freely use, modify, and distribute the code. For production use, you must either have an Additional Use Grant from the licensor or purchase a commercial license.

### [Link to section](https://fossa.com/blog/business-source-license-requirements-provisions-history/\#can-i-use-bsl-licensed-code-in-production) Can I use BSL-licensed code in production?

Generally, no. The BSL prohibits production use unless the licensor has granted an "Additional Use Grant" that covers your specific use case. If your production use isn't covered by an Additional Use Grant, you must purchase a commercial license from the licensor.

### [Link to section](https://fossa.com/blog/business-source-license-requirements-provisions-history/\#what-is-an-additional-use-grant) What is an Additional Use Grant?

An Additional Use Grant is a mechanism in BSL 1.1 that allows the licensor to specify circumstances where the licensed code can be used in production without purchasing a commercial license. For example, Hashicorp's BSL allows production use except for competitive products, while MariaDB allows production use with fewer than three server instances.

### [Link to section](https://fossa.com/blog/business-source-license-requirements-provisions-history/\#how-does-the-bsl-convert-to-an-open-source-license) How does the BSL convert to an open source license?

The BSL includes a "springing license" provision that automatically converts the license to a GPL-compatible open source license after a set period. The licensor can specify a "Change Date" within four years of the software version's release, and choose a "Change License" that must be GPL v2 or later, or GPL-compatible.

### [Link to section](https://fossa.com/blog/business-source-license-requirements-provisions-history/\#whats-the-difference-between-bsl-10-and-bsl-11) What's the difference between BSL 1.0 and BSL 1.1?

BSL 1.1 introduced several key changes: the Change License must be GPL-compatible (not required in 1.0), the Change Date must be within four years (no time limit in 1.0), and it uses "Additional Use Grants" to specify allowed production use (instead of "Usage Limitations" that prohibited specific uses).

### [Link to section](https://fossa.com/blog/business-source-license-requirements-provisions-history/\#why-would-a-company-choose-the-business-source-license) Why would a company choose the Business Source License?

Companies choose BSL to provide source code access (like open source) while maintaining control over commercial production use. This allows them to monetize their software while still benefiting from community contributions, transparency, and the eventual conversion to open source after the conversion period.

### Subscribe to our newsletter

Get the latest insights on open source license compliance and security delivered to your inbox.

Subscribe