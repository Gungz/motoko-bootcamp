import Result "mo:base/Result";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
import Nat64 "mo:base/Nat64";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import Types "types";

actor {

        type Result<A, B> = Result.Result<A, B>;
        type Member = Types.Member;
        type ProposalContent = Types.ProposalContent;
        type ProposalId = Types.ProposalId;
        type Proposal = Types.Proposal;
        type Vote = Types.Vote;
        type HttpRequest = Types.HttpRequest;
        type HttpResponse = Types.HttpResponse;

        // The principal of the Webpage canister associated with this DAO canister (needs to be updated with the ID of your Webpage canister)
        stable let canisterIdWebpage : Principal = Principal.fromText("3c7jb-myaaa-aaaab-qacoa-cai");
        stable var manifesto = "Motoko Bootcamp";
        stable let name = "Gungz";
        stable var goals : [Text] = [];

        let members = HashMap.HashMap<Principal, Member>(0, Principal.equal, Principal.hash);
        let initialMember : Member = {
                name = "motoko_bootcamp";
                role = #Mentor;
        };
        let initialMember_2 : Member = {
                name = "Gungz";
                role = #Mentor;
        };
        members.put(Principal.fromText("nkqop-siaaa-aaaaj-qa3qq-cai"), initialMember);
        members.put(Principal.fromText("fg5yi-sgh2p-pzcxk-fl4ok-p3eok-dmjoh-7zpui-dyxkx-j3y5g-utyw7-uqe"), initialMember_2);

        var nextProposalId : ProposalId = 0;
        let proposals = HashMap.HashMap<ProposalId, Proposal>(0, Nat.equal, Hash.hash);

        // Returns the name of the DAO
        public query func getName() : async Text {
                return name;
        };

        // Returns the manifesto of the DAO
        public query func getManifesto() : async Text {
                return manifesto;
        };

        // Returns the goals of the DAO
        public query func getGoals() : async [Text] {
                return goals;
        };

        // Register a new member in the DAO with the given name and principal of the caller
        // Airdrop 10 MBC tokens to the new member
        // New members are always Student
        // Returns an error if the member already exists
        public shared ({ caller }) func registerMember(member : Member) : async Result<(), Text> {
                let memberX : Member = {
                        name = member.name;
                        role = #Student;
                };
                let mbtCanister = actor("v4w3l-lyaaa-aaaab-qadma-cai") : actor {
                        mint : shared (owner : Principal, amount : Nat) -> async Result<(), Text>;
                };
                let result = await mbtCanister.mint(caller, 10);
                switch (members.get(caller)) {
                        case (null) {
                                members.put(caller, memberX);
                                return #ok();
                        };
                        case (?member) {
                                return #err("Member already exists");
                        };
                };
        };

        // Get the member with the given principal
        // Returns an error if the member does not exist
        public query func getMember(p : Principal) : async Result<Member, Text> {
                switch (members.get(p)) {
                        case (null) {
                                return #err("Member does not exist");
                        };
                        case (?member) {
                                return #ok(member);
                        };
                };
        };

        // Graduate the student with the given principal
        // Returns an error if the student does not exist or is not a student
        // Returns an error if the caller is not a mentor
        public shared ({ caller }) func graduate(student : Principal) : async Result<(), Text> {
                switch (members.get(student)) {
                        case (null) {
                                return #err("Student doesn't exists");
                        };
                        case (?member) {
                                switch(member.role) {
                                        case (#Graduate) {
                                                return #err("Student already graduates");
                                        };
                                        case (#Mentor) {
                                                return #err("Only student can be graduated");
                                        };
                                        case (#Student) {
                                                switch (members.get(caller)) {
                                                        case (null) {
                                                                return #err("Mentor doesn't exists");
                                                        };
                                                        case (?memberX) {
                                                                switch (memberX.role) {
                                                                        case (#Mentor) {
                                                                                let memberY : Member = {
                                                                                        name = member.name;
                                                                                        role = #Graduate;
                                                                                };
                                                                                members.put(student, memberY);
                                                                                return #ok();
                                                                        };
                                                                        case (_) {
                                                                                return #err("Only mentor can graduate stuent"); 
                                                                        };
                                                                };
                                                        };
                                                };
                                        };
                                }
                        };
                };
        };

        // Create a new proposal and returns its id
        // Returns an error if the caller is not a mentor or doesn't own at least 1 MBC token
        public shared ({ caller }) func createProposal(content : ProposalContent) : async Result<ProposalId, Text> {
                switch (members.get(caller)) {
                        case (null) {
                                return #err("The caller is not a member - cannot create a proposal");
                        };
                        case (?member) {
                                let mbtCanister = actor("v4w3l-lyaaa-aaaab-qadma-cai") : actor {
                                        balanceOf : shared (owner : Principal) -> async Nat;
                                        burn : shared (owner : Principal, amount : Nat) -> async Result<(), Text>;
                                };
                                let balance = await mbtCanister.balanceOf(caller);
                                if (balance < 1) {
                                        return #err("The caller does not have enough tokens to create a proposal");
                                };
                                switch (member.role) {
                                        case (#Mentor) {
                                                // Create the proposal and burn the tokens
                                                let proposal : Proposal = {
                                                        id = nextProposalId;
                                                        content;
                                                        creator = caller;
                                                        created = Time.now();
                                                        executed = null;
                                                        votes = [];
                                                        voteScore = 0;
                                                        status = #Open;
                                                };
                                                proposals.put(nextProposalId, proposal);
                                                nextProposalId += 1;
                                                let result = await mbtCanister.burn(caller, 1);
                                                return #ok(nextProposalId - 1);
                                        };
                                        case (_) {
                                                return #err("Only mentor can create a proposal");
                                        }
                                }
                                
                        };
                };
        };

        // Get the proposal with the given id
        // Returns an error if the proposal does not exist
        public query func getProposal(id : ProposalId) : async Result<Proposal, Text> {
                switch (proposals.get(id)) {
                        case (null) {
                                return #err("The proposal does not exist");
                        };
                        case (?proposal) {
                                return #ok(proposal);
                        };
                }
        };

        // Returns all the proposals
        public query func getAllProposal() : async [Proposal] {
                return Iter.toArray(proposals.vals());
        };

        // Vote for the given proposal
        // Returns an error if the proposal does not exist or the member is not allowed to vote
        public shared ({ caller }) func voteProposal(proposalId : ProposalId, yesOrNo : Bool) : async Result<(), Text> {
                switch (members.get(caller)) {
                        case (null) {
                                return #err("Member does not exist");
                        };
                        case (?member) {
                                if (member.role == #Student) {
                                        return #err("Student is not allowed to vote");
                                };
                                switch (proposals.get(proposalId)) {
                                        case (null) {
                                                return #err("The proposal does not exist");
                                        };
                                        case (?proposal) {
                                                let mbtCanister = actor("v4w3l-lyaaa-aaaab-qadma-cai") : actor {
                                                        balanceOf : shared (owner : Principal) -> async Nat;
                                                };

                                                // Check if the proposal is open for voting
                                                if (proposal.status != #Open) {
                                                        return #err("The proposal is not open for voting");
                                                };
                                                // Check if the caller has already voted
                                                if (_hasVoted(proposal, caller)) {
                                                        return #err("The caller has already voted on this proposal");
                                                };
                                                
                                                let multiplierVote = switch (yesOrNo) {
                                                        case (true) { 1 };
                                                        case (false) { -1 };
                                                };
                                                let balance = await mbtCanister.balanceOf(caller);
                                                let weight = if (member.role == #Graduate) {
                                                        1;
                                                } else {
                                                        5;
                                                };

                                                let newVoteScore = proposal.voteScore + balance * multiplierVote * weight;
                                                var newExecuted : ?Time.Time = null;
                                                let newVotes = Buffer.fromArray<Vote>(proposal.votes);
                                                let newStatus = if (newVoteScore >= 100) {
                                                        #Accepted;
                                                } else if (newVoteScore <= -100) {
                                                        #Rejected;
                                                } else {
                                                        #Open;
                                                };
                                                switch (newStatus) {
                                                        case (#Accepted) {
                                                                await _executeProposal(proposal.content);
                                                                newExecuted := ?Time.now();
                                                        };
                                                        case (_) {};
                                                };
                                                let newProposal : Proposal = {
                                                        id = proposal.id;
                                                        content = proposal.content;
                                                        creator = proposal.creator;
                                                        created = proposal.created;
                                                        executed = newExecuted;
                                                        votes = Buffer.toArray(newVotes);
                                                        voteScore = newVoteScore;
                                                        status = newStatus;
                                                };
                                                proposals.put(proposal.id, newProposal);
                                                return #ok();
                                        };
                                };

                        };
                };
        };

        // Returns the Principal ID of the Webpage canister associated with this DAO canister
        public query func getIdWebpage() : async Principal {
                return canisterIdWebpage;
        };

        func _hasVoted(proposal : Proposal, member : Principal) : Bool {
                return Array.find<Vote>(
                        proposal.votes,
                        func(vote : Vote) {
                                return vote.member == member;
                        },
                ) != null;
        };

        func _executeProposal(content : ProposalContent) : async () {
                switch (content) {
                        case (#ChangeManifesto(newManifest)) {
                                let webCanister = actor("3c7jb-myaaa-aaaab-qacoa-cai") : actor {
                                        setManifesto : shared (newManifesto : Text) ->  async Result<(), Text>;
                                };
                                let result = await webCanister.setManifesto(newManifest);
                        };
                        case (#AddGoal(newGoal)) {
                                let goalsX = Buffer.Buffer<Text>(0);
                                for (goal in goals.vals()) {
                                        goalsX.add(goal);
                                };
                                goalsX.add(newGoal);
                                goals := Buffer.toArray(goalsX);
                        };
                        case (#AddMentor(principal)) {
                                switch (members.get(principal)) {
                                        case (null) {
                                                return;
                                        };
                                        case (?member) {
                                                if (member.role == #Graduate) {
                                                        let memberX : Member = {
                                                                name = member.name;
                                                                role = #Mentor;
                                                        };
                                                        members.put(principal, member);
                                                };
                                        };
                                };
                        };

                };
                return;
        };

};
