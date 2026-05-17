package lab.mbean;

import javax.management.MBeanServer;
import javax.management.ObjectName;
import java.lang.management.ManagementFactory;

public class MBeanRegistry {
    private static final PointsCounter pointsCounter = new PointsCounter();
    private static final ClickInterval clickInterval = new ClickInterval();

    public static void registerMBeans() {
        try {
            MBeanServer mbs = ManagementFactory.getPlatformMBeanServer();
            
            ObjectName pointsName = new ObjectName("lab.mbean:type=PointsCounter");
            if (!mbs.isRegistered(pointsName)) {
                mbs.registerMBean(pointsCounter, pointsName);
            }
            
            ObjectName clickName = new ObjectName("lab.mbean:type=ClickInterval");
            if (!mbs.isRegistered(clickName)) {
                mbs.registerMBean(clickInterval, clickName);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static PointsCounter getPointsCounter() {
        return pointsCounter;
    }

    public static ClickInterval getClickInterval() {
        return clickInterval;
    }
}
