package lab.mbean;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

@WebListener
public class MBeanContextListener implements ServletContextListener {
    @Override
    public void contextInitialized(ServletContextEvent sce) {
        MBeanRegistry.registerMBeans();
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
    }
}
