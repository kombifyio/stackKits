[![The Redis License Has Changed: What You Need to Know](https://www.percona.com/blog/wp-content/uploads/2025/09/Redis-License-has-Changed.jpg)](https://www.percona.com/blog/the-redis-license-has-changed-what-you-need-to-know/)

[Insight for DBAs](https://www.percona.com/blog/category/dba-insight/) [Open Source](https://www.percona.com/blog/category/open-source/) [Valkey](https://www.percona.com/blog/category/valkey/)

[Subscribe to RSS Feed](https://www.percona.com/blog/feed)

# The Redis License Has Changed: What You Need to Know

October 1, 2025

[David Quilty](https://www.percona.com/blog/author/david-quilty)

Redis has always been the go-to when you need fast, in-memory data storage. You’ll find it everywhere. Big ecommerce sites. Mobile apps. Maybe your own projects, too.

But if you’re relying on Redis today, you’re facing a new reality: the licensing terms have changed, and that shift could affect the way you use Redis going forward.

The new Redis license isn’t just some boring legal update; it affects how teams deploy, share, and even build with Redis. This especially matters if you run large apps or offer managed services. There’s a lot of noise and confusion out there. Let’s clear it up.

We’ll cover:

- _What’s actually different now_
- _What new risks or headaches you should know about_
- _What you can do to keep your options open_

## So, what changed with the Redis license?

If you’ve used Redis for a while, you probably remember the old days. No licensing headaches. Just download and go. That changed with Redis 7.4.

Here’s what’s new:

### No more BSD freedom

Redis is no longer what most people consider “open source.” The BSD license made Redis simple to use anywhere, for anything. That’s off the table now. If you care about open source, this is a real change.

### A tangle of new licenses

Redis now ships under three different licenses:

- **AGPLv3**: Open source in name, but much stricter. If you run Redis as a networked service and tweak the code, you’re expected to release those changes.
- **RSALv2** (Redis Source Available License): You can use Redis for your own projects and apps, but offering it as a managed service is prohibited.
- **SSPLv1**: Even stricter. If you provide Redis as a service, you’d have to share your whole service codebase with the world.

### Features may have different rules

Not everything in Redis uses the same license now. Some new features or modules might only come under stricter terms. You’ll need to check before you upgrade or add anything new.

### Managed and hosted services are the big target

If you’re just running Redis for your own business, you might not notice an immediate difference. But if your company offers Redis as a cloud or SaaS feature, you’re now facing legal and operational roadblocks. Even if you’re running internal platform services, you need to know where you stand before rolling out new versions.

### Packaging is already changing

Some Linux distributions and package managers are dropping Redis or moving slowly on updates because it no longer fits their open source policies. That means installing or upgrading Redis could become more complicated over time.

### Upgrades come with homework

For most teams, the days of “just update Redis” are probably over. Now, every new release might require a legal review. This adds friction, but it’s necessary to avoid headaches later.

### The community is splitting

The licensing change sparked the creation of Valkey, a fully open source fork now led by the Linux Foundation. This may lead to Redis and Valkey going in different directions over time.

**The bottom line**: The Redis license change affects how you use, update, and build on Redis. If open source, flexibility, or avoiding vendor surprises are important to you, you’ll want to pay close attention.

## What does this mean for teams using Redis?

If you’re running Redis today, this license change isn’t something to ignore. The practical effects depend on how you use Redis and where your organization is heading.

**For teams using Redis internally:** You’ll probably keep humming along for now. But start making a habit of reading the license notes before any upgrade or new feature. Some releases may add new rules.

**If your company offers Redis as a managed, hosted, or SaaS solution:** This is where the impact is immediate. The new license blocks you from offering Redis as a service unless you want to share your code or make a commercial deal. If Redis is something you sell, you need to review your plans asap.

**For those embedding or distributing Redis in a product:** Shipping Redis as part of your hardware or software? The new license affects what you can include, support, or even update. Every new release could change your requirements. Loop in your legal and product teams.

**Upgrade planning is now a team sport:** It’s not just about the latest features anymore. Upgrades may need input from legal, compliance, and support. The risk isn’t only technical; it’s legal and operational, too.

**Expect some ecosystem shakeups:** With open source distributions and package managers rethinking their relationship with Redis, you may find updates or support less straightforward than before. Plan for extra steps.

## Are there open source alternatives to Redis?

Yes. If your team depends on open source software, or you just want to skip future licensing headaches, you’re not out of luck. As mentioned earlier, the community quickly responded to the Redis license change by launching [Valkey](https://hubs.ly/Q03Jwhb40), a new fork of Redis. Valkey is governed by the Linux Foundation and released under the permissive BSD license, so it remains fully open source and free from vendor lock-in.

Valkey aims to deliver the familiar speed and flexibility teams expect from Redis, while protecting the open source values many organizations rely on. For some, it’s a direct path to keeping their data infrastructure simple and predictable.

Of course, switching technologies raises its own set of questions. That’s where having the right support and guidance becomes critical.

## Need help making sense of it all? We’ve got your back.

Licensing changes shouldn’t leave you stuck, scrambling, or second-guessing your next move. Whether you’re planning to stay on Redis, exploring Valkey, or just want to make sure your current environment stays secure and high-performing, having the right support matters more than ever.

That’s exactly why Percona offers 24/7, enterprise-grade support and consulting for both Redis and Valkey. Our team has experience with both technologies, and our only agenda is making sure you have what you need to run reliably.

Thinking about migrating? Need help with compliance, upgrades, or day-to-day operations? We’re here to help you chart the best path forward on your terms.

[Learn more about Percona Support for Redis and Valkey](https://hubs.ly/Q03Jwh0k0)

### Share This Post!

Subscribe

Notify of

new follow-up commentsnew replies to my comments

![guest](https://secure.gravatar.com/avatar/18a3280de6d9b483ee6c438d97c47ef365e0e4f12b978eb34864b661fe41cb42?s=56&d=mm&r=g)

Label

{}\[+\]

Name\*

Email\*

Website

Δ

![guest](data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%2056%2056'%3E%3C/svg%3E)

Label

{}\[+\]

Name\*

Email\*

Website

Δ

0 Comments

Oldest

NewestMost Voted

Inline Feedbacks

View all comments

## Stay up to date with the Percona Blog

Email\*

reCAPTCHA

Recaptcha requires verification.

protected by **reCAPTCHA**

[Privacy](https://www.google.com/intl/en/policies/privacy/) \- [Terms](https://www.google.com/intl/en/policies/terms/)

[Privacy](https://www.google.com/intl/en/policies/privacy/) \- [Terms](https://www.google.com/intl/en/policies/terms/)

![right-img](data:image/svg+xml,%3Csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%201%201'%3E%3C/svg%3E)

## Related Blog Articles

### RECOMMENDED ARTICLES

[![Semantic Caching for LLM Apps: Reduce Costs by 40-80% and Speed up by 250x](https://www.percona.com/blog/wp-content/uploads/2026/02/Semantic-Caching-for-LLM-Apps.jpg)](https://www.percona.com/blog/semantic-caching-for-llm-apps-reduce-costs-by-40-80-and-speed-up-by-250x/)

[**Semantic Caching for LLM Apps: Reduce Costs by 40-80% and Speed up by 250x**](https://www.percona.com/blog/semantic-caching-for-llm-apps-reduce-costs-by-40-80-and-speed-up-by-250x/)

[Database Trends](https://www.percona.com/blog/category/database-trends/) [Insight for Developers](https://www.percona.com/blog/category/developer-insight/) [Open Source](https://www.percona.com/blog/category/open-source/) [Valkey](https://www.percona.com/blog/category/valkey/)

[![Percona at 20: Why Our Open Source, Services-Led Model Still Works](https://www.percona.com/blog/wp-content/uploads/2026/02/Percona-at-20-Why-Our-Open-Source-Services-Led-Model-Still-Works.jpg)](https://www.percona.com/blog/percona-at-20-why-our-open-source-services-led-model-still-works/)

[**Percona at 20: Why Our Open Source, Services-Led Model Still Works**](https://www.percona.com/blog/percona-at-20-why-our-open-source-services-led-model-still-works/)

[Database Trends](https://www.percona.com/blog/category/database-trends/) [Open Source](https://www.percona.com/blog/category/open-source/) [Percona Announcements](https://www.percona.com/blog/category/percona-announcements/)

[![Importance of Tuning Checkpoint in PostgreSQL](https://www.percona.com/blog/wp-content/uploads/2026/02/Importance-of-Tuning-Checkpoint-in-PostgreSQL.jpg)](https://www.percona.com/blog/importance-of-tuning-checkpoint-in-postgresql/)

[**Importance of Tuning Checkpoint in PostgreSQL**](https://www.percona.com/blog/importance-of-tuning-checkpoint-in-postgresql/)

[Insight for DBAs](https://www.percona.com/blog/category/dba-insight/) [Insight for Developers](https://www.percona.com/blog/category/developer-insight/) [PostgreSQL](https://www.percona.com/blog/category/postgresql/)

### MOST POPULAR ARTICLES

[![Deploy Django on Kubernetes With Percona Operator for PostgreSQL](https://www.percona.com/blog/wp-content/uploads/2023/03/lucas.speyer_an_icon_of_an_electronic_cloud_orange_sunrise_colo_3073ada1-8b7c-4a9b-879a-331eb856b2f1.png)](https://www.percona.com/blog/deploy-django-on-kubernetes-with-percona-operator-for-postgresql/)

[**Deploy Django on Kubernetes With Percona Operator for PostgreSQL**](https://www.percona.com/blog/deploy-django-on-kubernetes-with-percona-operator-for-postgresql/)

[Cloud](https://www.percona.com/blog/category/cloud/) [Insight for Developers](https://www.percona.com/blog/category/developer-insight/) [Percona Software](https://www.percona.com/blog/category/percona-software/) [PostgreSQL](https://www.percona.com/blog/category/postgresql/)

[![MySQL Performance Tuning: Maximizing Database Efficiency and Speed](https://www.percona.com/blog/wp-content/uploads/2023/03/block-chains-with-black-background-3d-rendering-1.jpg)](https://www.percona.com/blog/mysql-101-parameters-to-tune-for-mysql-performance/)

[**MySQL Performance Tuning: Maximizing Database Efficiency and Speed**](https://www.percona.com/blog/mysql-101-parameters-to-tune-for-mysql-performance/)

[Insight for DBAs](https://www.percona.com/blog/category/dba-insight/) [Monitoring](https://www.percona.com/blog/category/monitoring/) [MySQL](https://www.percona.com/blog/category/mysql/)

[![The Ultimate Guide to Open Source Databases](https://www.percona.com/blog/wp-content/uploads/2023/03/featured-img.jpg)](https://www.percona.com/blog/ultimate-guide-open-source-databases)

[**The Ultimate Guide to Open Source Databases**](https://www.percona.com/blog/ultimate-guide-open-source-databases)

[Insight for DBAs](https://www.percona.com/blog/category/dba-insight/)

wpDiscuz

Insert

reCAPTCHA

Select all images with a **bus** Click verify once there are none left.

|     |     |     |
| --- | --- | --- |
| ![](https://www.google.com/recaptcha/enterprise/payload?p=06AFcWeA6b-REMrwPV2UZ889kiLv_1GPWQQfMIzfpd2vb7I54zpUACMltR5VbDIF5Ty8Nuopi1fOM5t5qVn9-c4D4r_F-AShkDlo2ZqUfjoRGWdQ1_8jTYw4Z5aO5WMeksk8Fl9M0BX4vh7ZaxSaAQ0DvbYev-dGIemSGUBRVx6kDLPM752sq-Gbb-UAWdHAXx_sMPS3TuwXYv&k=6Ld_ad8ZAAAAAAqr0ePo1dUfAi0m4KPkCMQYwPPm) | ![](https://www.google.com/recaptcha/enterprise/payload?p=06AFcWeA6b-REMrwPV2UZ889kiLv_1GPWQQfMIzfpd2vb7I54zpUACMltR5VbDIF5Ty8Nuopi1fOM5t5qVn9-c4D4r_F-AShkDlo2ZqUfjoRGWdQ1_8jTYw4Z5aO5WMeksk8Fl9M0BX4vh7ZaxSaAQ0DvbYev-dGIemSGUBRVx6kDLPM752sq-Gbb-UAWdHAXx_sMPS3TuwXYv&k=6Ld_ad8ZAAAAAAqr0ePo1dUfAi0m4KPkCMQYwPPm) | ![](https://www.google.com/recaptcha/enterprise/payload?p=06AFcWeA6b-REMrwPV2UZ889kiLv_1GPWQQfMIzfpd2vb7I54zpUACMltR5VbDIF5Ty8Nuopi1fOM5t5qVn9-c4D4r_F-AShkDlo2ZqUfjoRGWdQ1_8jTYw4Z5aO5WMeksk8Fl9M0BX4vh7ZaxSaAQ0DvbYev-dGIemSGUBRVx6kDLPM752sq-Gbb-UAWdHAXx_sMPS3TuwXYv&k=6Ld_ad8ZAAAAAAqr0ePo1dUfAi0m4KPkCMQYwPPm) |
| ![](https://www.google.com/recaptcha/enterprise/payload?p=06AFcWeA6b-REMrwPV2UZ889kiLv_1GPWQQfMIzfpd2vb7I54zpUACMltR5VbDIF5Ty8Nuopi1fOM5t5qVn9-c4D4r_F-AShkDlo2ZqUfjoRGWdQ1_8jTYw4Z5aO5WMeksk8Fl9M0BX4vh7ZaxSaAQ0DvbYev-dGIemSGUBRVx6kDLPM752sq-Gbb-UAWdHAXx_sMPS3TuwXYv&k=6Ld_ad8ZAAAAAAqr0ePo1dUfAi0m4KPkCMQYwPPm) | ![](https://www.google.com/recaptcha/enterprise/payload?p=06AFcWeA6b-REMrwPV2UZ889kiLv_1GPWQQfMIzfpd2vb7I54zpUACMltR5VbDIF5Ty8Nuopi1fOM5t5qVn9-c4D4r_F-AShkDlo2ZqUfjoRGWdQ1_8jTYw4Z5aO5WMeksk8Fl9M0BX4vh7ZaxSaAQ0DvbYev-dGIemSGUBRVx6kDLPM752sq-Gbb-UAWdHAXx_sMPS3TuwXYv&k=6Ld_ad8ZAAAAAAqr0ePo1dUfAi0m4KPkCMQYwPPm) | ![](https://www.google.com/recaptcha/enterprise/payload?p=06AFcWeA6b-REMrwPV2UZ889kiLv_1GPWQQfMIzfpd2vb7I54zpUACMltR5VbDIF5Ty8Nuopi1fOM5t5qVn9-c4D4r_F-AShkDlo2ZqUfjoRGWdQ1_8jTYw4Z5aO5WMeksk8Fl9M0BX4vh7ZaxSaAQ0DvbYev-dGIemSGUBRVx6kDLPM752sq-Gbb-UAWdHAXx_sMPS3TuwXYv&k=6Ld_ad8ZAAAAAAqr0ePo1dUfAi0m4KPkCMQYwPPm) |
| ![](https://www.google.com/recaptcha/enterprise/payload?p=06AFcWeA6b-REMrwPV2UZ889kiLv_1GPWQQfMIzfpd2vb7I54zpUACMltR5VbDIF5Ty8Nuopi1fOM5t5qVn9-c4D4r_F-AShkDlo2ZqUfjoRGWdQ1_8jTYw4Z5aO5WMeksk8Fl9M0BX4vh7ZaxSaAQ0DvbYev-dGIemSGUBRVx6kDLPM752sq-Gbb-UAWdHAXx_sMPS3TuwXYv&k=6Ld_ad8ZAAAAAAqr0ePo1dUfAi0m4KPkCMQYwPPm) | ![](https://www.google.com/recaptcha/enterprise/payload?p=06AFcWeA6b-REMrwPV2UZ889kiLv_1GPWQQfMIzfpd2vb7I54zpUACMltR5VbDIF5Ty8Nuopi1fOM5t5qVn9-c4D4r_F-AShkDlo2ZqUfjoRGWdQ1_8jTYw4Z5aO5WMeksk8Fl9M0BX4vh7ZaxSaAQ0DvbYev-dGIemSGUBRVx6kDLPM752sq-Gbb-UAWdHAXx_sMPS3TuwXYv&k=6Ld_ad8ZAAAAAAqr0ePo1dUfAi0m4KPkCMQYwPPm) | ![](https://www.google.com/recaptcha/enterprise/payload?p=06AFcWeA6b-REMrwPV2UZ889kiLv_1GPWQQfMIzfpd2vb7I54zpUACMltR5VbDIF5Ty8Nuopi1fOM5t5qVn9-c4D4r_F-AShkDlo2ZqUfjoRGWdQ1_8jTYw4Z5aO5WMeksk8Fl9M0BX4vh7ZaxSaAQ0DvbYev-dGIemSGUBRVx6kDLPM752sq-Gbb-UAWdHAXx_sMPS3TuwXYv&k=6Ld_ad8ZAAAAAAqr0ePo1dUfAi0m4KPkCMQYwPPm) |

Please try again.

Please select all matching images.

Please also check the new images.

Please select around the object, or reload if there are none.

Verify

reCAPTCHA

Select all images with **crosswalks** Click verify once there are none left.

|     |     |     |
| --- | --- | --- |
| ![](https://www.google.com/recaptcha/enterprise/payload?p=06AFcWeA4XgcJ7zaflnnquhgso6gt79O1a7usGrALZ7ZJhTS_M1mOJgXXj7MMP4jf8oaWd8-lNw9WGTBcLM_0TLXPpnUYYlL0YtVMTpnkAbtbWCDhojWdra4BsAP-3mkKEi7WuLs7z9s3nGChbhnY9pC2_cJlgaf2ELz5jbdN0uzqEqVZiI1E41TphUy4ih4oT2WWjA9xX8uSEYdn3matXmJZvGbHfafM4TQ&k=6Ld_ad8ZAAAAAAqr0ePo1dUfAi0m4KPkCMQYwPPm) | ![](https://www.google.com/recaptcha/enterprise/payload?p=06AFcWeA4XgcJ7zaflnnquhgso6gt79O1a7usGrALZ7ZJhTS_M1mOJgXXj7MMP4jf8oaWd8-lNw9WGTBcLM_0TLXPpnUYYlL0YtVMTpnkAbtbWCDhojWdra4BsAP-3mkKEi7WuLs7z9s3nGChbhnY9pC2_cJlgaf2ELz5jbdN0uzqEqVZiI1E41TphUy4ih4oT2WWjA9xX8uSEYdn3matXmJZvGbHfafM4TQ&k=6Ld_ad8ZAAAAAAqr0ePo1dUfAi0m4KPkCMQYwPPm) | ![](https://www.google.com/recaptcha/enterprise/payload?p=06AFcWeA4XgcJ7zaflnnquhgso6gt79O1a7usGrALZ7ZJhTS_M1mOJgXXj7MMP4jf8oaWd8-lNw9WGTBcLM_0TLXPpnUYYlL0YtVMTpnkAbtbWCDhojWdra4BsAP-3mkKEi7WuLs7z9s3nGChbhnY9pC2_cJlgaf2ELz5jbdN0uzqEqVZiI1E41TphUy4ih4oT2WWjA9xX8uSEYdn3matXmJZvGbHfafM4TQ&k=6Ld_ad8ZAAAAAAqr0ePo1dUfAi0m4KPkCMQYwPPm) |
| ![](https://www.google.com/recaptcha/enterprise/payload?p=06AFcWeA4XgcJ7zaflnnquhgso6gt79O1a7usGrALZ7ZJhTS_M1mOJgXXj7MMP4jf8oaWd8-lNw9WGTBcLM_0TLXPpnUYYlL0YtVMTpnkAbtbWCDhojWdra4BsAP-3mkKEi7WuLs7z9s3nGChbhnY9pC2_cJlgaf2ELz5jbdN0uzqEqVZiI1E41TphUy4ih4oT2WWjA9xX8uSEYdn3matXmJZvGbHfafM4TQ&k=6Ld_ad8ZAAAAAAqr0ePo1dUfAi0m4KPkCMQYwPPm) | ![](https://www.google.com/recaptcha/enterprise/payload?p=06AFcWeA4XgcJ7zaflnnquhgso6gt79O1a7usGrALZ7ZJhTS_M1mOJgXXj7MMP4jf8oaWd8-lNw9WGTBcLM_0TLXPpnUYYlL0YtVMTpnkAbtbWCDhojWdra4BsAP-3mkKEi7WuLs7z9s3nGChbhnY9pC2_cJlgaf2ELz5jbdN0uzqEqVZiI1E41TphUy4ih4oT2WWjA9xX8uSEYdn3matXmJZvGbHfafM4TQ&k=6Ld_ad8ZAAAAAAqr0ePo1dUfAi0m4KPkCMQYwPPm) | ![](https://www.google.com/recaptcha/enterprise/payload?p=06AFcWeA4XgcJ7zaflnnquhgso6gt79O1a7usGrALZ7ZJhTS_M1mOJgXXj7MMP4jf8oaWd8-lNw9WGTBcLM_0TLXPpnUYYlL0YtVMTpnkAbtbWCDhojWdra4BsAP-3mkKEi7WuLs7z9s3nGChbhnY9pC2_cJlgaf2ELz5jbdN0uzqEqVZiI1E41TphUy4ih4oT2WWjA9xX8uSEYdn3matXmJZvGbHfafM4TQ&k=6Ld_ad8ZAAAAAAqr0ePo1dUfAi0m4KPkCMQYwPPm) |
| ![](https://www.google.com/recaptcha/enterprise/payload?p=06AFcWeA4XgcJ7zaflnnquhgso6gt79O1a7usGrALZ7ZJhTS_M1mOJgXXj7MMP4jf8oaWd8-lNw9WGTBcLM_0TLXPpnUYYlL0YtVMTpnkAbtbWCDhojWdra4BsAP-3mkKEi7WuLs7z9s3nGChbhnY9pC2_cJlgaf2ELz5jbdN0uzqEqVZiI1E41TphUy4ih4oT2WWjA9xX8uSEYdn3matXmJZvGbHfafM4TQ&k=6Ld_ad8ZAAAAAAqr0ePo1dUfAi0m4KPkCMQYwPPm) | ![](https://www.google.com/recaptcha/enterprise/payload?p=06AFcWeA4XgcJ7zaflnnquhgso6gt79O1a7usGrALZ7ZJhTS_M1mOJgXXj7MMP4jf8oaWd8-lNw9WGTBcLM_0TLXPpnUYYlL0YtVMTpnkAbtbWCDhojWdra4BsAP-3mkKEi7WuLs7z9s3nGChbhnY9pC2_cJlgaf2ELz5jbdN0uzqEqVZiI1E41TphUy4ih4oT2WWjA9xX8uSEYdn3matXmJZvGbHfafM4TQ&k=6Ld_ad8ZAAAAAAqr0ePo1dUfAi0m4KPkCMQYwPPm) | ![](https://www.google.com/recaptcha/enterprise/payload?p=06AFcWeA4XgcJ7zaflnnquhgso6gt79O1a7usGrALZ7ZJhTS_M1mOJgXXj7MMP4jf8oaWd8-lNw9WGTBcLM_0TLXPpnUYYlL0YtVMTpnkAbtbWCDhojWdra4BsAP-3mkKEi7WuLs7z9s3nGChbhnY9pC2_cJlgaf2ELz5jbdN0uzqEqVZiI1E41TphUy4ih4oT2WWjA9xX8uSEYdn3matXmJZvGbHfafM4TQ&k=6Ld_ad8ZAAAAAAqr0ePo1dUfAi0m4KPkCMQYwPPm) |

Please try again.

Please select all matching images.

Please also check the new images.

Please select around the object, or reload if there are none.

Verify