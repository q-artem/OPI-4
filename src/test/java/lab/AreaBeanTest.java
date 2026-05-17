package lab;

import static org.junit.Assert.*;

import java.util.Arrays;
import java.util.Collection;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameters;

@RunWith(Parameterized.class)
public class AreaBeanTest {

    private final int x;
    private final double y;
    private final double r;
    private final boolean expected;
    private final String description;

    private AreaBean bean;

    public AreaBeanTest(
        int x,
        double y,
        double r,
        boolean expected,
        String description
    ) {
        this.x = x;
        this.y = y;
        this.r = r;
        this.expected = expected;
        this.description = description;
    }

    @Parameters(name = "{4}")
    public static Collection<Object[]> data() {
        return Arrays.asList(
            new Object[][] {
                { -1, 0.5, 2.0, true, "q2_rectangle" },
                { 0, 0.0, 1.0, true, "q2_boundary" },
                { -1, 1.5, 2.0, false, "q2_outside" },
                { -1, -1.0, 2.0, true, "q3_inside" },
                { -2, -1.0, 2.0, false, "q3_tooLeft" },
                { -1, -3.0, 2.0, false, "q3_tooLow" },
                { 1, -1.0, 2.0, true, "q4_inside" },
                { 2, 0.0, 2.0, true, "q4_boundary" },
                { 2, -2.0, 2.0, false, "q4_outside" },
                { 1, 1.0, 2.0, false, "q1" },
                { 0, 0.0, 0.0, true, "zeroRadius" },
            }
        );
    }

    @Before
    public void setUp() {
        bean = new AreaBean(null);
    }

    @Test
    public void checkHit_returnsExpected() {
        bean.setX(x);
        bean.setY(y);
        assertEquals(description, expected, bean.checkHit(r));
    }
}
