package lab;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class ResultManager {
    private static final String URL = System
            .getenv()
            .getOrDefault("DATABASE_URL", "jdbc:postgresql://localhost:5432/studs");
    private static final String USER = System.getenv().getOrDefault("DATABASE_USER", "s467731");
    private static final String PASSWORD = System.getenv().getOrDefault("DATABASE_PASSWORD", "ytsQfxwJ8XS0zLjM");

    private final Connection connection;

    public ResultManager() {
        try {
            this.connection = DriverManager.getConnection(URL, USER, PASSWORD);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    private ResultSet execute(String query) throws SQLException {
        PreparedStatement statement = this.connection.prepareStatement(query);
        return statement.executeQuery();
    }

    private ResultSet execute(String query, Object... args) throws SQLException {
        PreparedStatement statement = this.connection.prepareStatement(query);
        for (int i = 0; i < args.length; i++) {
            statement.setObject(i + 1, args[i]);
        }
        return statement.executeQuery();
    }

    private Result parseRow(ResultSet resultSet) throws SQLException {
        int id = resultSet.getInt("id");
        int x = resultSet.getInt("x");
        double y = resultSet.getDouble("y");
        double r = resultSet.getDouble("r");
        boolean hit = resultSet.getBoolean("hit");
        return new Result(id, x, y, r, hit);
    }

    public List<Result> getResults() {
        try {
            List<Result> results = new ArrayList<>();

            ResultSet resultSet = this.execute("SELECT * FROM results ORDER BY id DESC");
            while (resultSet.next()) {
                results.add(parseRow(resultSet));
            }

            return results;
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    public Result insertResult(int x, double y, double r, boolean hit) {
        try {
            String sql = "INSERT INTO results(x, y, r, hit) VALUES (?, ?, ?, ?) RETURNING *";
            ResultSet resultSet = this.execute(sql, x, y, r, hit);

            if (!resultSet.next()) {
                throw new RuntimeException("INSERT INTO must return value");
            }

            return parseRow(resultSet);
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
}
