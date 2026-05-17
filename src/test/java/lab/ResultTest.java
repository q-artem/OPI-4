package lab;

import static org.junit.Assert.*;

import java.util.Arrays;
import java.util.Collection;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameters;

@RunWith(Parameterized.class)
public class ResultTest {

    private final int id;
    private final int x;
    private final double y;
    private final double r;
    private final boolean hit;

    public ResultTest(int id, int x, double y, double r, boolean hit) {
        this.id = id;
        this.x = x;
        this.y = y;
        this.r = r;
        this.hit = hit;
    }

    @Parameters(name = "id={0} x={1} y={2} r={3} hit={4}")
    public static Collection<Object[]> data() {
        return Arrays.asList(
            new Object[][] {
                { 1, 2, 3.5, 2.0, true },
                { 5, 1, -1.0, 3.0, false },
                { 2, -5, -3.14, 1.5, false },
            }
        );
    }

    @Test
    public void constructor_fieldsPreserved() {
        Result result = new Result(id, x, y, r, hit);
        assertEquals(id, result.getId());
        assertEquals(x, result.getX());
        assertEquals(y, result.getY(), 0.001);
        assertEquals(r, result.getR(), 0.001);
        assertEquals(hit, result.isHit());
    }

    @Test
    public void setters_changeValues() {
        Result result = new Result(0, 0, 0, 0, false);
        result.setId(10);
        result.setX(-3);
        result.setY(1.1);
        result.setR(2.5);
        result.setHit(true);

        assertEquals(10, result.getId());
        assertEquals(-3, result.getX());
        assertEquals(1.1, result.getY(), 0.001);
        assertEquals(2.5, result.getR(), 0.001);
        assertTrue(result.isHit());
    }
}
