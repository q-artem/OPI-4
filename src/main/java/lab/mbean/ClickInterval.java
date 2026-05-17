package lab.mbean;

public class ClickInterval implements ClickIntervalMBean {
    private long lastClickTime = -1;
    private long totalInterval = 0;
    private long clickCount = 0;

    @Override
    public synchronized double getAverageInterval() {
        if (clickCount == 0) return 0;
        return (double) totalInterval / clickCount;
    }

    public synchronized void recordClick() {
        long currentTime = System.currentTimeMillis();
        if (lastClickTime != -1) {
            totalInterval += (currentTime - lastClickTime);
            clickCount++;
        }
        lastClickTime = currentTime;
    }
}
