package lab.mbean;

import javax.management.MBeanNotificationInfo;
import javax.management.Notification;
import javax.management.NotificationBroadcasterSupport;

public class PointsCounter extends NotificationBroadcasterSupport implements PointsCounterMBean {
    private long totalPoints = 0;
    private long hitPoints = 0;
    private long sequenceNumber = 1;

    @Override
    public long getTotalPoints() {
        return totalPoints;
    }

    @Override
    public long getHitPoints() {
        return hitPoints;
    }

    public synchronized void addPoint(boolean hit) {
        totalPoints++;
        if (hit) {
            hitPoints++;
        }

        if (totalPoints % 15 == 0) {
            Notification notification = new Notification(
                "lab.mbean.points.multipleOf15",
                this,
                sequenceNumber++,
                System.currentTimeMillis(),
                "Total points reached a multiple of 15: " + totalPoints
            );
            sendNotification(notification);
        }
    }

    @Override
    public MBeanNotificationInfo[] getNotificationInfo() {
        String[] types = new String[]{ "lab.mbean.points.multipleOf15" };
        String name = Notification.class.getName();
        String description = "Notification sent when total points is a multiple of 15";
        MBeanNotificationInfo info = new MBeanNotificationInfo(types, name, description);
        return new MBeanNotificationInfo[]{ info };
    }
}
