event addResource: machine
event startTx:()
event sendPrepare: machine
event receivePrepareSuccessful: machine
event receivePrepareFailure: machine
event sendRollback: machine
event receiveCommitSuccessful: machine
event sendCommit: machine
event receiveCommitSuccessful: machine
event endTx:()

spec twoPhaseCommit {
    var participants: set[machine];
    var countPrepareMsgs: int = 0;
    var countPreparedMachines: int = 0;
    var countRollbackMsgs: int = 0;
    var countRolledbackMachines: int  = 0;
    var countCommitMsgs: int = 0;
    var countCommittedMachines: int = 0; 

    start state Init {
        on addResource do (m: machine) {
            participants += m;
        }

        on startTx do () {
            goto SendAndReceivePrepareMsgs;       
        }
    }

    state SendAndReceivePrepareMsgs {
        on sendPrepare do (m: machine) {
            countPrepareMsgs += 1;
        }

        on receivePrepareSuccessful do (m: machine) {
            countPreparedMachines += 1;
            if (countPrepareMsgs == sizeof(participants) && countPreparedMachines == sizeof(participants)) {
                goto SendAndReceiveCommitMsgs;
            }
        }

        on receivePrepareFailure do (m: machine) {
            goto SendAndReceiveRollbackMsgs;
        }
    }

    state SendAndReceiveRollbackMsgs {
        on receivePrepareSuccessful do (m: machine) {
        }

        on receivePrepareFailure do (m: machine) {
        }

        on sendRollback do (m: machine) {
            countRollbackMsgs += 1;
        }

        on receiveRollbackSuccessful do (m: machine) {
            countRolledbackMachines += 1;
        }

	on endTx do () {
	    assert(countRollbackMsgs == sizeof(participants) && countRollbackMachines == sizeof(participants));
	}

    }

    state SendAndReceiveCommitMsgs {
        on sendCommit do (m: machine) {
            countCommitMsgs += 1;
        }

        on receiveCommitSuccessful do (m: machine) {
            countCommitMachines += 1;
        }

	on endTx do () {
            assert(countCommitMsgs == sizeof(participants) && countCommittedMachines == sizeof(participants));
	}
    }
}

