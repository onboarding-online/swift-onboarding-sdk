OnboardingiOSSDK [![Swift](https://github.com/onboarding-online/swift-onboarding-sdk/actions/workflows/swift.yml/badge.svg)](https://github.com/onboarding-online/swift-onboarding-sdk/actions/workflows/swift.yml)
===

## Documentation
All documentation about IOS Onboarding Online SDK, including integration, can be found [here](https://intercom.help/onboarding-online/en/collections/5974926-onboarding-online-sdk-integration)

## To contribute
* Install [Swift](https://www.swift.org/getting-started/) version 5 or higher
* Install [Node.js](http://nodejs.org) version 18 or use [nvm](https://github.com/nvm-sh/nvm#installing-and-updating).
* Install [@commitlint/cli](https://www.npmjs.com/package/@commitlint/cli) globally
* Install [@commitlint/config-conventional](https://www.npmjs.com/package/@commitlint/config-conventional) globally
* Install [pre-commit](https://pre-commit.com/)
* Install git hooks ``pre-commit install``
* Install [standard-version](https://www.npmjs.com/package/standard-version) globally
* Install [gh](https://cli.github.com/manual/installation) version 2 or higher

## To release
* ``standard-version``
* ``git push --follow-tags origin main``
* ``gh release create v1.X.X -F CHANGELOG.md``

## Contribution rules
Please use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) rules when create some commit.
