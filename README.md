# Sloth’s Ledger App
![GitHub release](https://img.shields.io/github/v/release/slothmock/sloth_ledger)
![GitHub downloads](https://img.shields.io/github/downloads/slothmock/sloth_ledger/total)
![License](https://img.shields.io/github/license/slothmock/sloth_ledger)
![Status](https://img.shields.io/badge/status-early%20development-orange)
![Platform](https://img.shields.io/badge/platform-Android-green)
![Privacy](https://img.shields.io/badge/data-local%20only-success)

I built this Ledger App to help manage my finances in a way that felt intentional, private, and easy.  
The app works as a manual ledger where the user can create different account types such as cash or debit accounts and transfer funds between them (when they share the same currency).  
All transactions are manually entered instead of connecting to a bank or third-party service. This means that every balance exists because the user recorded it.  
  
Transactions are grouped by day with a running total shown at the top which makes it easy to see how much has been made/spent.  
The app can track subscriptions in a separate module which integrates with the Ledger. The user sees the next due date, amount, and the account a subscription will be paid from.  
The app highlights subscriptions that are coming up or overdue so nothing slips by unnoticed. Marking a subscription as 'Paid' also adds the transaction to the Ledger automatically.  
(Ledger Transaction -> Subscription is planned) 

I created this because I wanted something simple, private, and free. 
If this app helps someone (or anyone) else, that's amazing, but it's primarily built for my own financial clarity.

## Personal Roadmap

This project is changing as my financial needs change.  
If you build/download a release - a future version will more than likely have breaking changes so please bear this in mind.  

### Planned areas of development include:

- Improved recurring and subscription handling
- Clearer asset and liability separation
- Budgeting module development
- Investment tracking for traditional assets
- Crypto account support
- Foreign exchange support for multi currency accounts

- Tests

## Development Approach

This app is built with the support of modern AI tooling. AI is used as a "productivity multiplier" during development, not as a substitute for architectural thinking. 
The structure and long term direction of the system are built and maintained by myself.

If AI assisted development is a *big* concern for you, feel free to review the code and suggest the **many improvements** it no doubt has.  
Refactors and thoughtful feedback are always welcome.

## Technical Overview

Sloth’s Ledger App is built with Flutter and uses a ledger driven architecture where transactions are the single source of truth.  
Balances are never treated as authoritative stored values (aside from user-defined starting balances). Instead, they are derived from the transaction history associated with each account. This avoids state drift and ensures that every financial number can be traced back to explicit entries in the ledger.  
State management is handled using Provider. Core financial state is separated from UI components, with dedicated state classes responsible for accounts, transactions, subscriptions, and application initialization. The UI consumes this state reactively rather than embedding business logic inside widgets.  
Data persistence is local first and powered by SQLite. A repository layer abstracts database access from the rest of the application. This keeps storage concerns isolated and allows the ledger logic to remain focused on financial calculations rather than persistence details.  
Application startup is gated through an initialization layer that prepares the database and loads required state before the main interface becomes interactive. This keeps bootstrapping predictable and prevents partial state rendering.  
The architecture is modular by intention. Subscriptions are implemented as structured data that ultimately resolve into ledger relevant behaviour. Future modules such as budgeting, investments, and crypto accounts will extend the same ledger core rather than maintaining parallel financial systems.  

The guiding constraint is simple. Transactions define reality. Everything else is a computed view of that reality.

## Expectations

This is a personal project. It may change frequently. Features may evolve or be refactored as the architecture matures.
