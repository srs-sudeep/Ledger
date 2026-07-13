from typing import TypedDict


class NetBalance(TypedDict):
    userId: str
    balance: int


class SimplifiedTransaction(TypedDict):
    from_: str
    to: str
    amount: int


def simplify_debts(balances: list[NetBalance]) -> list[dict]:
    creditors: list[NetBalance] = []
    debtors: list[NetBalance] = []

    for b in balances:
        if b["balance"] > 0:
            creditors.append({"userId": b["userId"], "balance": b["balance"]})
        elif b["balance"] < 0:
            debtors.append({"userId": b["userId"], "balance": abs(b["balance"])})

    creditors.sort(key=lambda x: x["balance"], reverse=True)
    debtors.sort(key=lambda x: x["balance"], reverse=True)

    transactions: list[dict] = []
    i = j = 0

    while i < len(debtors) and j < len(creditors):
        amount = min(debtors[i]["balance"], creditors[j]["balance"])
        if amount > 0:
            transactions.append(
                {"from": debtors[i]["userId"], "to": creditors[j]["userId"], "amount": amount}
            )
        debtors[i]["balance"] -= amount
        creditors[j]["balance"] -= amount
        if debtors[i]["balance"] == 0:
            i += 1
        if creditors[j]["balance"] == 0:
            j += 1

    return transactions


def compute_group_balances(
    expenses: list,
    splits: list,
    settlements: list,
) -> dict[str, int]:
    balance_map: dict[str, int] = {}
    expense_payers = {str(e.id): str(e.payer_id) for e in expenses}

    def ensure(uid: str) -> None:
        if uid not in balance_map:
            balance_map[uid] = 0

    for split in splits:
        payer_id = expense_payers.get(str(split.expense_id))
        if not payer_id:
            continue
        user_id = str(split.user_id)
        ensure(payer_id)
        ensure(user_id)
        if user_id != payer_id:
            balance_map[payer_id] += split.owed_amount
            balance_map[user_id] -= split.owed_amount

    for s in settlements:
        f = str(s.from_user_id)
        t = str(s.to_user_id)
        ensure(f)
        ensure(t)
        balance_map[f] += s.amount
        balance_map[t] -= s.amount

    return balance_map
