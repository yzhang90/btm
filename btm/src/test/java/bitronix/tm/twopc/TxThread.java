package bitronix.tm.twopc;

import bitronix.tm.BitronixTransactionManager;
import bitronix.tm.mock.resource.MockXAResource;
import bitronix.tm.mock.resource.jdbc.MockitoXADataSource;
import bitronix.tm.resource.jdbc.PooledConnectionProxy;
import bitronix.tm.resource.jdbc.PoolingDataSource;
import javax.transaction.xa.XAException;
import bitronix.tm.mock.AbstractMockJdbcTest;

import javax.sql.XAConnection;
import java.sql.Connection;


public class TxThread extends Thread {

    private int tid;
    private BitronixTransactionManager tm;
    private boolean txSuccess;

    public TxThread(int tid, BitronixTransactionManager tm, boolean success) {
        this.tid = tid;
        this.tm = tm;
        this.txSuccess = success;
    }

    @Override
    public void run() {

        System.out.println(String.format("start Tx %d", tid));
        PoolingDataSource poolingDataSource1 = new PoolingDataSource();
        poolingDataSource1.setClassName(MockitoXADataSource.class.getName());
        poolingDataSource1.setUniqueName(String.format("pds-%d-1", tid));
        poolingDataSource1.setMinPoolSize(5);
        poolingDataSource1.setMaxPoolSize(5);
        poolingDataSource1.setAutomaticEnlistingEnabled(true);
        poolingDataSource1.init();


        PoolingDataSource poolingDataSource2 = new PoolingDataSource();
        poolingDataSource2.setClassName(MockitoXADataSource.class.getName());
        poolingDataSource2.setUniqueName(String.format("pds-%d-2", tid));
        poolingDataSource2.setMinPoolSize(5);
        poolingDataSource2.setMaxPoolSize(5);
        poolingDataSource2.setAutomaticEnlistingEnabled(true);
        poolingDataSource2.init();

        try {
            tm.begin();
            tm.setTransactionTimeout(10); // TX must not timeout

            Connection connection1 = poolingDataSource1.getConnection();
            connection1.createStatement();

            Connection connection2 = poolingDataSource2.getConnection();
            PooledConnectionProxy handle = (PooledConnectionProxy) connection2;
            XAConnection xaConnection2 = (XAConnection) AbstractMockJdbcTest.getWrappedXAConnectionOf(handle.getPooledConnection());
            connection2.createStatement();

            MockXAResource mockXAResource2 = (MockXAResource) xaConnection2.getXAResource();
            if(!txSuccess) {
                mockXAResource2.setPrepareException(createXAException("resource 2 prepare failed", XAException.XAER_RMERR));
            }


            tm.commit();
        } catch (Exception e) {} 
    }

    private XAException createXAException(String msg, int errorCode) {
        XAException prepareException = new XAException(msg);
        prepareException.errorCode = errorCode;
        return prepareException;
    }

}
