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

    private Connection connection;

    public ResultManager() {
        initConnection();
    }

    private void initConnection() {
        try {
            Class.forName("org.postgresql.Driver");
            this.connection = DriverManager.getConnection(URL, USER, PASSWORD);
        } catch (SQLException | ClassNotFoundException e) {
            System.err.println("Failed to connect to database: " + e.getMessage());
        }
    }

    private Connection getConnection() throws SQLException {
        if (connection == null || connection.isClosed()) {
            initConnection();
        }
        return connection;
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
        String sql = "SELECT * FROM results ORDER BY id DESC";
        try (PreparedStatement statement = getConnection().prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            
            List<Result> results = new ArrayList<>();
            while (resultSet.next()) {
                results.add(parseRow(resultSet));
            }
            return results;
        } catch (SQLException e) {
            System.err.println("Error getting results: " + e.getMessage());
            return new ArrayList<>();
        }
    }

    public Result insertResult(int x, double y, double r, boolean hit) {
        String sql = "INSERT INTO results(x, y, r, hit) VALUES (?, ?, ?, ?) RETURNING *";
        try (PreparedStatement statement = getConnection().prepareStatement(sql)) {
            statement.setInt(1, x);
            statement.setDouble(2, y);
            statement.setDouble(3, r);
            statement.setBoolean(4, hit);
            
            try (ResultSet resultSet = statement.executeQuery()) {
                if (!resultSet.next()) {
                    throw new RuntimeException("INSERT INTO must return value");
                }
                return parseRow(resultSet);
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error inserting result: " + e.getMessage(), e);
        }
    }
}
