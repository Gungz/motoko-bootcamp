import Result "mo:base/Result";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Option "mo:base/Option";
import Types "types";
actor {

    type Result<Ok, Err> = Types.Result<Ok, Err>;
    type HashMap<K, V> = Types.HashMap<K, V>;

    let ledger = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);

    public query func tokenName() : async Text {
        return "Gungz";
    };

    public query func tokenSymbol() : async Text {
        return "GUN";
    };

    public func mint(owner : Principal, amount : Nat) : async Result<(), Text> {
        let balance = Option.get(ledger.get(owner), 0);
        ledger.put(owner, balance + amount);
        return #ok();
    };

    public func burn(owner : Principal, amount : Nat) : async Result<(), Text> {
        let balance = Option.get(ledger.get(owner), 0);
        if (balance < amount) {
            return #err("Balance is lower than amount to be burned");
        };
        ledger.put(owner, balance - amount);
        return #ok();
        
    };

    public shared ({ caller }) func transfer(from : Principal, to : Principal, amount : Nat) : async Result<(), Text> {
        if (from == to) {
            return #err("Cannot transfer to self");
        };
        let balanceFrom = Option.get(ledger.get(from), 0);
        if (balanceFrom < amount) {
            return #err("Insufficient balance to transfer");
        };
        let balanceTo = Option.get(ledger.get(to), 0);
        ledger.put(from, balanceFrom - amount);
        ledger.put(to, balanceTo + amount);
        return #ok();
    };

    public query func balanceOf(account : Principal) : async Nat {
        return Option.get(ledger.get(account), 0);
    };

    public query func totalSupply() : async Nat {
        var sum = 0;
        for (value in ledger.vals()) {
            sum += value;
        };
        return sum;
    };

};