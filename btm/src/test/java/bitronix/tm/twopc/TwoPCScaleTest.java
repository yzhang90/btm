package bitronix.tm.twopc;

import bitronix.tm.BitronixTransactionManager;
import bitronix.tm.TransactionManagerServices;
import bitronix.tm.journal.Journal;
import bitronix.tm.mock.resource.MockJournal;
import bitronix.tm.mock.AbstractMockJdbcTest;
import javax.transaction.xa.XAException;

import java.lang.reflect.Field;
import java.util.concurrent.atomic.AtomicReference;

import junit.framework.TestCase;


public class TwoPCScaleTest extends TestCase {


    public void testTransaction() throws Exception {
        // change disk journal into mock journal
        Field field = TransactionManagerServices.class.getDeclaredField("journalRef");
        field.setAccessible(true);
        @SuppressWarnings("unchecked")
        AtomicReference<Journal> journalRef = (AtomicReference<Journal>) field.get(TransactionManagerServices.class);
        journalRef.set(new MockJournal());

        BitronixTransactionManager tm = TransactionManagerServices.getTransactionManager();

        for(int r = 0; r < 1000; r++) {
            TxThread[] txs = new TxThread[10];

            for (int i = 0; i < txs.length; i++) {
                if(i % 10 == 0) {
                    txs[i] = new TxThread(r*10 + i, tm, false);
                } else {
                    txs[i] = new TxThread(r*10 + i, tm, true);
                }
                txs[i].start();
            }

            for (TxThread tx : txs) {
                try {
                   tx.join();
                } catch (InterruptedException e) {
                   e.printStackTrace();
                }
            }
        }

        tm.shutdown();
    }

}
