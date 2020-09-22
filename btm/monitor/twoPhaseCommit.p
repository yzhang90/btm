event addResource: machine;
event startTx;
event sendPrepare: machine;
event receivePrepareSuccess: machine;
event receivePrepareFailure: machine;
event sendRollback: machine;
event receiveRollbackSuccess: machine;
event sendCommit: machine;
event receiveCommitSuccess: machine;
event endTx;

spec twoPhaseCommit observes addResource, startTx, sendPrepare, receivePrepareSuccess, receivePrepareFailure, sendRollback, receiveRollbackSuccess, sendCommit, receiveCommitSuccess, endTx {
    var participants: map[machine, bool];
    var countPrepareMsgs: int;
    var countPreparedMachines: int;
    var countRollbackMsgs: int;
    var countRolledbackMachines: int;
    var countCommitMsgs: int;
    var countCommittedMachines: int; 

    start state Init {
        entry {
            countPrepareMsgs = 0;
            countPreparedMachines = 0;
            countRollbackMsgs = 0;
            countRolledbackMachines = 0;
            countCommitMsgs = 0;
            countCommittedMachines = 0;
        }
        on addResource do (m: machine) {
            participants[m] = true;
        }

        on startTx do {
            goto SendAndReceivePrepareMsgs;       
        }
    }

    state SendAndReceivePrepareMsgs {
        on sendPrepare do (m: machine) {
            countPrepareMsgs = countPrepareMsgs + 1;
        }

        on receivePrepareSuccess do (m: machine) {
            countPreparedMachines = countPreparedMachines + 1;
            if (countPrepareMsgs == sizeof(participants) && countPreparedMachines == sizeof(participants)) {
                goto SendAndReceiveCommitMsgs;
            }
        }

        on receivePrepareFailure do (m: machine) {
            goto SendAndReceiveRollbackMsgs;
        }
    }

    state SendAndReceiveRollbackMsgs {
        on sendPrepare do (m: machine) {
        }

        on receivePrepareSuccess do (m: machine) {
        }

        on receivePrepareFailure do (m: machine) {
        }

        on sendRollback do (m: machine) {
            countRollbackMsgs = countRollbackMsgs + 1;
        }

        on receiveRollbackSuccess do (m: machine) {
            countRolledbackMachines = countRolledbackMachines + 1;
        }

        on endTx do {
            assert(countRollbackMsgs == sizeof(participants) && countRolledbackMachines == sizeof(participants));
        }
    }

    state SendAndReceiveCommitMsgs {
        on sendCommit do (m: machine) {
            countCommitMsgs = countCommitMsgs + 1;
        }

        on receiveCommitSuccess do (m: machine) {
            countCommittedMachines = countCommittedMachines + 1;
        }

        on endTx do {
            assert(countCommitMsgs == sizeof(participants) && countCommittedMachines == sizeof(participants));
        }
    }
}
