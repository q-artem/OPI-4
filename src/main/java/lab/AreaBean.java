package lab;

import java.io.Serializable;
import java.util.List;

import javax.faces.bean.ManagedBean;
import javax.faces.bean.RequestScoped;

@SuppressWarnings("deprecation")
@RequestScoped
@ManagedBean(name = "area")
public class AreaBean implements Serializable {
    public ResultManager resultManager;

    public int x = 1;
    public double y = 1;

    public boolean r10;
    public boolean r15;
    public boolean r20 = true;
    public boolean r25;
    public boolean r30;

    public AreaBean() {
        this.resultManager = new ResultManager();
    }
    
    AreaBean(ResultManager resultManager) {
        this.resultManager = resultManager;
    }

    public boolean checkHit(double r) {
        return (x <= 0 && y >= 0 && x + r >= y)
                || (x <= 0 && y <= 0 && x >= -r / 2 && y >= -r)
                || (x >= 0 && y <= 0 && x * x + y * y <= r * r);
    }

    private void processResult(double r) {
        resultManager.insertResult(x, y, r, checkHit(r));
    }

    public void checkPoint() {
        if (r10)
            processResult(1.0);
        if (r15)
            processResult(1.5);
        if (r20)
            processResult(2.0);
        if (r25)
            processResult(2.5);
        if (r30)
            processResult(3.0);
    }

    public List<Result> getResults() {
        return resultManager.getResults();
    }

    public int getX() {
        return x;
    }

    public void setX(int x) {
        this.x = x;
    }

    public double getY() {
        return y;
    }

    public void setY(double y) {
        this.y = y;
    }

    public boolean isR10() {
        return r10;
    }

    public void setR10(boolean r10) {
        this.r10 = r10;
    }

    public boolean isR15() {
        return r15;
    }

    public void setR15(boolean r15) {
        this.r15 = r15;
    }

    public boolean isR20() {
        return r20;
    }

    public void setR20(boolean r20) {
        this.r20 = r20;
    }

    public boolean isR25() {
        return r25;
    }

    public void setR25(boolean r25) {
        this.r25 = r25;
    }

    public boolean isR30() {
        return r30;
    }

    public void setR30(boolean r30) {
        this.r30 = r30;
    }
}
