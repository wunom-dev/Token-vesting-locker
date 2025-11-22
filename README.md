Token-Vesting-Locker
A secure and transparent token vesting smart contract for managing scheduled token releases on the Stacks blockchain.

---

Overview

**Token-Vesting-Locker** provides a reliable mechanism for locking tokens and releasing them gradually over a predefined vesting schedule.  
It is ideal for:

- Team token allocations  
- Investor vesting  
- Advisor rewards  
- Long-term project sustainability  

The contract ensures tokens are released only after meeting vesting conditions, preventing premature access and promoting accountability.

---

Key Features

Linear or Cliff Vesting
Supports:
- **Cliff vesting** (tokens unlock after a fixed period)
- **Linear vesting** (tokens unlock gradually over time)

Secure Token Locking
- Locked tokens cannot be withdrawn before their scheduled release.
- Fully on-chain and immutable behavior.

Multiple Beneficiaries
- Create vesting schedules for different recipients.
- Each schedule is tracked independently.

Transparent Vesting State
- View vested amount  
- View claimable tokens  
- View remaining locked balance  

Event Logging
Key events include:
- Vesting schedule creation  
- Token claims  
- Vesting completion  

---

Contract Structure

| File | Description |
|------|-------------|
| `token-vesting-locker.clar` | Main vesting contract implementation |
| `token-vesting-locker_test.ts` | Test suite for verifying vesting logic |
| `Clarinet.toml` | Clarinet project configuration |
| `README.md` | Project documentation |

---

How It Works

1. **Create a Vesting Schedule**
A project owner initializes a vesting schedule with:
- Beneficiary address  
- Total token amount  
- Start block  
- Cliff duration  
- Vesting duration  

2. **Tokens Are Locked**
Tokens are transferred into the contract and held until vesting conditions are met.

3. **Beneficiary Claims Tokens**
As vesting progresses, the beneficiary can claim available vested tokens.

---

Usage (Basic Flow)

```
(create-vesting beneficiary amount start-block cliff-duration vesting-duration)
(get-claimable-tokens beneficiary)
(claim-tokens beneficiary)
(get-vesting-info beneficiary)
```

---

Testing

The test suite covers:

- Vesting schedule creation  
- Cliff and linear unlocking  
- Token claim validation  
- Edge cases and access control  

Run tests using:

```
clarinet test
```

---

License

This project is open-source under the MIT License.

---

Contribution

Contributions, audits, and feature improvements are welcome.  
Please submit issues or pull requests for enhancements or bug fixes.

