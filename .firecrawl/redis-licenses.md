All eyes on AI: 2026 predictions – The shifts that will shape your stack.

[Read now](http://redis.io/2026-predictions/)

[Back to legal hub](https://redis.io/legal/)

# Licenses

## Redis Licensing Overview

- [Redis Open Source](https://github.com/redis/redis) is available as both source available and OSI-compliant open source software. A user may select one of the following three license options to use Redis Open Source (starting with Redis 8) and subsequent versions: the Redis Source Available License v2 ( [RSALv2](https://redis.io/legal/rsalv2-agreement/)), the Server Side Public License v1 ( [SSPLv1](https://www.mongodb.com/legal/licensing/server-side-public-license)), and the GNU Affero General Public License v3 ( [AGPLv3](https://www.gnu.org/licenses/agpl-3.0.en.html)).
- Redis proprietary products are closed source and require a commercial license from Redis Ltd. For information on Redis Cloud licensing, read more [here](https://redis.io/legal/cloud-tos/). For more information on Redis Software licensing, read more [here](https://redis.io/legal/software-agreement/).

### About RSALv2

[RSALv2](https://redis.io/legal/rsalv2-agreement/) is a permissive, non-copyleft license created by Redis Ltd., allowing users the right to “use, copy, distribute, make available, and prepare derivative works of the software” and has only two primary limitations. You may not:

- Commercialize the software or provide it to others as a managed service in a way that provides the functionality of the Software available to third parties; and
- Remove or obscure any licensing, copyright, or other notices.

RSALv2 is not an open source license.

### About SSPLv1

[SSPLv1](https://www.mongodb.com/licensing/server-side-public-license) is a source-available license created by MongoDB, allowing free and unrestricted use, modification, and redistribution, with the simple requirement that if you provide the product as a service to others, you must also publicly release any modifications as well as the source code of your management layers under SSPL.

SSPLv1 is based on GPLv3, and is considered a copyleft license. This means that if you use the source code and create derivative works, those derivative works must also be licensed under SSPL and released publicly. For more information, please consult this MongoDB [FAQ](https://www.mongodb.com/licensing/server-side-public-license/faq).

SSPLv1 is not an open source license.

### About AGPLv3

[AGPLv3](https://www.gnu.org/licenses/agpl-3.0.en.html) is an open source license introduced by the Free Software Foundation specifically designed for code that runs over a network and requires users to make the complete source code and any modifications publicly available upon distribution

AGPLv3 is a copyleft license. This means that if you use the source code and create derivative works, those derivative works must also be licensed under AGPLv3 and released publicly. For more information, please consult this Free Software Foundation [FAQ](https://www.gnu.org/licenses/gpl-faq.html).

AGPLv3 is an OSI-approved open source license.

### About our tri-license

Redis 8 in Redis Open Source and later versions are available under our tri-license, allowing us to be both source-available and open source software. Our tri-license includes RSALv2, SSPLv1, and AGPLv3.

RediSearch, RedisJSON, RedisTimeSeries, and RedisBloom are now included as integral components of Redis Open Source and subject to the same tri-license. Starting with Redis 8, the version numbers of all included modules are identical to the version number of Redis Open Source they are included in.

### About past licenses

Redis 7.2.x of Redis Open Source and earlier versions remain subject to the BSD3 license. Redis Community Edition 7.4.x to 7.8.x remain subject to the dual RSALv2/SSPLv1 license.

Certain Redis modules created by Redis Ltd. (e.g., [RediSearch](https://redis.io/docs/stack/search/), [RedisJSON](https://redis.io/docs/stack/json/), [RedisTimeSeries](https://redis.io/docs/stack/timeseries/), and [RedisBloom](https://redis.io/docs/stack/bloom/)) are now also tri-licensed under RSALv2, SSPLv1, and AGPLv3 with the general availability of Redis 8.

Read more about the full version history in the table below.

| Version | 7.2 and earlier | 7.4 | 8+ |
| --- | --- | --- | --- |
| Referred to as | Redis | Redis Community Edition | Redis Open Source |
| License | BSD-3-Clause | RSALv2 or SSPLv1 | RSALv2 or SSPLv1 or AGPLv3 |

### About Redis Insight and Redis for VS Code

Redis Insight and Redis for VS Code are visual tools that let you explore data, design, develop, and optimize your applications while also serving as a platform for Redis education and onboarding. Redis Insight specifically integrates Redis Copilot, a natural language AI assistant that improves the experience when working with data and commands.

Both Redis Insight and Redis for VS Code are provided under a commercial license to paying Redis customers. Community users and non-paying individuals use these tools under the SSPLv1 license.

## FAQ

### What is the new license for Redis Open Source?

Redis Ltd. is adding a third license option to its Redis Open Source offerings. In addition to SSPLv1 and RSALv2, users can now choose the free and OSI-approved open-source AGPLv3 license. This update is effective starting with the general availability release of Redis 8. This is not a license change, but rather the inclusion of an option to provide more flexibility for the Redis community.

### Why did Redis add AGPLv3?

Some community members were frustrated by our March 2024 license change to the dual-license RSALv2 and SSPLv1, neither of which are OSI-approved licenses. Our license change was in response to the managed service providers who used Redis 7.2 and prior versions under the BSD3 license but provided limited contributions. The license change forced those providers to face a choice – share their source code according to the SSPLv1 license, or move on from Redis. Some chose to move on.

Quoting our CEO’s blog post from March 2024: “Organizations providing competitive offerings to Redis will no longer be permitted to use new versions of the source code of Redis free of charge under either of the dual licenses. If you are building a solution that leverages Redis, but does not specifically compete with Redis itself, there is no impact.”

Redis has been able to innovate more rapidly in the year following the change and is excited to again provide Redis Open Source under an OSI-approved license.

### How is AGPLv3 different from the BSD3 license?

The [BSD3](https://opensource.org/license/bsd-3-clause) license and [AGPLv3](https://www.gnu.org/licenses/agpl-3.0.en.html) represent different approaches to open source licensing. BSD3 is a permissive license that allows users to do almost anything with the code—including using it in proprietary software—as long as they retain the copyright notice and disclaimers. In contrast, AGPLv3 is a copyleft license that requires any modified versions to be distributed under the same terms, with the additional requirement that source code must be made available to users who interact with the software over a network. This “network clause” is AGPLv3’s defining feature, designed specifically to ensure that users of web applications can access the source code.

### Sure, but what if Redis changes the license again?

There are no plans to change or add to the current Redis Open Source license configuration. Because our primary motivation for changing our license to RSALv2/SSPLv1 has now been successfully achieved, we can better align with Redis community expectations. We invested a lot of time to consider different licenses and to analyze the market dynamics before choosing AGPLv3. Other companies have made AGPLv3 an option for their communities as well.

Let us be clear: we plan to keep Redis Open Source under the AGPLv3 license because we concluded that this license suits our business model and license stability is essential for the community. We recognize that our community is a founding pillar of Redis and we will keep it this way forever.

### I am a Redis community user. Am I impacted by the addition of AGPLv3?

The short answer is: most likely not.

If you are switching from Redis Community Edition (version 7.4.x or later) or from Redis Stack to Redis 8 the answer is simple: No.

If you are switching from an earlier Redis Open Source version (7.2 or earlier) and using the code or artifacts provided by Redis, as-is, the answer is simple again: No.

If you are switching from an earlier Redis Open Source version (7.2 or earlier), using modified code, and it is offered as a network server, the operators of those servers are required to provide the source code of the modified version running there to the users of that server.

### I’m a customer or partner; how does AGPLv3 as a license option affect me?

This change does not affect customers and partners using our Redis Cloud or Software products under a commercial license.

### I am using a Redis fork. Why should I consider Redis?

Redis Ltd. is the company that stands behind Redis. Our main mission as a company is focused on furthering Redis for the benefit of the Redis community. Redis does not have conflicting interests. We set the vision for Redis and execute on it. No other entity is prioritizing and investing in a Redis-like product as much as we do in Redis. We are laser-focused on making Redis more performant, scalable, user-friendly, and innovative. We constantly see forks and imitators copying portions of our innovation and APIs, but they are many months and often years behind us.

Our investments extend beyond Redis Open Source to the Redis ecosystem. We make sure all developer tools and resources in other repositories fully support our latest innovations. That includes our official Redis client libraries, Redis Insight, Redis Copilot, and Redis for VS Code. And of course, we maintain the official Redis documentation.

We also stand behind our community. Whenever we introduce new features, we help onboard them with Redis Insight interactive guides and tutorials, support our community on a dedicated discord channel, are very attentive to community requests on Github, and help community members on Stack Overflow and Reddit. Our official documentation covers not just Redis APIs, but also all the client library APIs.

For further clarification, please reach us at [redis\_licensing@redis.com](mailto:redis_licensing@redis.com).

## Full license information

| Product | Version | License & Terms |
| --- | --- | --- |
| Redis (Open Source) | <= 7.2 | BSD-3-Clause |
| Redis Community Edition | 7.4 | RSALv2 or SSPLv1 |
| Redis Open Source | >= 8.0.0 | RSALv2 or SSPLv1 or AGPLv3 |
| Redis Stack | <= 6.2.4 | RSALv1 |
| Redis Stack | >= 6.2.6 | RSALv2 or SSPLv1 |
| Redis Software | any | see https://redis.io/software-subscription-agreement/ |
| Redis Data Integration | any | same as Redis Software |
| Redis Cloud | any | see https://redis.io/legal/cloud-tos/ |

| Module | Version | License & Terms |
| --- | --- | --- |
| RediSearch | <= 1.2 | AGPLv3 |
| RediSearch | >= 1.4 to <= 1.4.3 | Apache v2.0 modified with Commons Clause |
| RediSearch | >= 1.4.4 to <= 2.4 | RSALv1 |
| RediSearch | >= 2.6 to <= 2.10 | RSALv2 or SSPLv1 |
| RedisJSON | <= 1.0.2 | AGPLv3 |
| RedisJSON | 1.0.3 | Apache v2.0 modified with Commons Clause |
| RedisJSON | >= 1.0.4 to <= 2.2 | RSALv1 |
| RedisJSON | >= 2.4 to <= 2.8 | RSALv2 or SSPLv1 |
| RedisBloom | < 2.0 | AGPLv3 |
| RedisBloom | >= 2.0 to <= 2.2 | RSALv1 |
| RedisBloom | >= 2.4 to <= 2.8 | RSALv2 or SSPLv1 |
| RedisTimeSeries | <=1.6 | RSALv1 |
| RedisTimeSeries | >=1.8 to <= 1.12 | RSALv2 or SSPLv1 |
| RedisGraph | < 1.0.14 | Apache v2.0 modified with Commons Clause |
| RedisGraph | >= 1.0.14 to <= 2.8 | RSALv1 |
| RedisGraph | >= 2.10 | RSALv2 or SSPLv1 |
| RedisGears | <= 1.2 | RSALv1 |
| RedisGears | >= 2.0 | RSALv2 or SSPLv1 |

| Tool | Version | License & Terms |
| --- | --- | --- |
| Redis Insight | < 2.0 | see https://redis.io/legal/redis-insight-license-terms/ |
| Redis Insight | >= 2.0 | SSPLv1 |
| Redis for VS Code | any | SSPLv1 |

| Client & Library | Version | License & Terms |
| --- | --- | --- |
| redis-py | any | MIT |
| redis-vl-python | any | MIT |
| NRedisStack | any | MIT |
| ioredis | any | MIT |
| node-redis | any | MIT |
| jedis | any | MIT |
| lettuce | any | MIT |
| redis-rb | any | MIT |
| hiredis | any | BSD-3-Clause |
| go-redis | any | BSD-2-Clause |
| rueidis | any | Apache v2.0 |

## Get started with Redis today

Speak to a Redis expert and learn more about enterprise-grade Redis today.

[Try for free](https://redis.io/try-free/) [Talk to sales](https://redis.io/meeting/)

This site uses cookies and related technologies, as described in our [privacy policy](https://redis.com/legal/privacy-policy/), for purposes that may include site operation, analytics, enhanced user experience, or advertising. You may choose to consent to our use of these technologies, or manage your own preferences.

Manage SettingsAccept