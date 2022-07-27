# JDBC学习知识梳理

> 作        者：keysen
>
> 开始时间：
>
> 完成时间：

[TOC]

## 1、准备

参考链接：
https://jdbc.postgresql.org/

42.x的Documentation https://jdbc.postgresql.org/documentation/documentation.html

Maven 依赖：https://mvnrepository.com/artifact/org.postgresql/postgresql

说明：

PostgreSQL版本：9.6.8

JAVA SDK：1.8.0.211

JDBC：42.2.6



## 2、初始化驱动程序

本章描述如何在你的程序中加载和初始化JDBC驱动

### 2.1、导入JDBC

所有使用JDBC的源都需要导入 `java.sql`包，使用

```java
import java.sql.*;
```

注意：除非您没有使用JDBC API的标准PostgreSQL™扩展，否则不应导入org.postgresql包。

### 2.2、连接示例



```java
import com.alibaba.fastjson.JSON;
import com.ctgcache.pgsql.entity.PgDatabase;
import com.ctgcache.pgsql.vo.PgDatabaseReqVO;
import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.*;

public class JDBCUtil {
    private static Logger logger = LoggerFactory.getLogger(JDBCUtil.class);

    /**
     * jdbc 连接 pgsql
     * @param ip
     * @param pgPort
     * @param pgUser
     * @param password
     * @return
     * @throws SQLException
     */
    private static Connection getConnection(String ip, String pgPort, String pgUser, String password) throws SQLException {
        Connection connection = null;
        String url = "jdbc:postgresql://" + ip + ":" + pgPort + "/postgres";
        connection = DriverManager.getConnection(url, pgUser, password);
        return connection;
    }

    /**
     * 判断节点是否为主库：是主库返回true；备库返回false；
     * @param ip
     * @param pgPort
     * @param pgUser
     * @param pw
     * @return
     * @throws SQLException
     */
    public static Boolean isPrimaryNode(String ip, String pgPort, String pgUser, String pw) throws SQLException{
        Connection connection = getConnection(ip, pgPort, pgUser, pw);
        String flag = null;

        Statement statement = connection.createStatement();
        ResultSet resultSet = statement.executeQuery("select * from pg_is_in_recovery()");
        if(resultSet.next()) {
            flag = resultSet.getString(1);
        }

        closeConnection(connection, statement, resultSet);
        if (flag.equals("f"))
            return true;
        else
            return false;
    }

    /**
     * 判断用户是否存在，存在返回true，否则返回false；
     * @param ip
     * @param pgPort
     * @param pgUser
     * @param pw
     * @param roleName
     * @return
     * @throws SQLException
     */
    public static Boolean isUserExisted(String ip, String pgPort, String pgUser, String pw, String roleName) throws SQLException{
        Connection connection = getConnection(ip, pgPort, pgUser, pw);
        Boolean flag = false;

        Statement statement = connection.createStatement();
        String sql = "select 1 from pg_roles where rolname=\'" + roleName+ "\';";
        ResultSet resultSet = statement.executeQuery(sql);
        if(resultSet.next()) {
            if (resultSet.getString(1).equals("1")) {
                logger.info("用户存在！！！");
                flag = true;
            }
        }

        closeConnection(connection, statement, resultSet);
        return flag;
    }

	/**
     * 查询某个数据库的 encoding、ctype、collate
     * @param ip
     * @param pgPort
     * @param pgUser
     * @param pw
     * @param dbName
     * @return
     * @throws SQLException
     */
    public static PgDatabase queryWithDbName(String ip, String pgPort, String pgUser, String pw, String dbName) throws SQLException{
        Connection connection = getConnection(ip, pgPort, pgUser, pw);
        Boolean flag = false;
        PgDatabase pgDatabase = new PgDatabase();

        Statement statement = connection.createStatement();
        String sql = "SELECT pg_catalog.pg_encoding_to_char(d.encoding) as \"Encoding\","
                + " d.datcollate as \"Collate\","
                + " d.datctype as \"Ctype\","
                + " d.datname as \"Name\""
                + " FROM pg_catalog.pg_database d"
                + " WHERE d.datname = \'" + dbName + "\'";
        ResultSet resultSet = statement.executeQuery(sql);
        if(resultSet.next()) {
            pgDatabase.setDbEncoding(resultSet.getString("Encoding"));
            pgDatabase.setDbCtype(resultSet.getString("Ctype"));
            pgDatabase.setDbCollate(resultSet.getString("Collate"));
        }
        closeConnection(connection, statement, resultSet);
        return pgDatabase;
    }

    /**
     * 判断数据库是否存在，存在返回true，否则返回false
     * @param ip
     * @param pgPort
     * @param pgUser
     * @param pw
     * @param dbName
     * @return
     * @throws SQLException
     */
    public static Boolean isDatabaseExisted(String ip, String pgPort, String pgUser, String pw, String dbName) throws SQLException{
        Connection connection = getConnection(ip, pgPort, pgUser, pw);
        Boolean flag = false;

        Statement statement = connection.createStatement();
        String sql = "select 1 from pg_database where datname=\'" + dbName+ "\';";
        ResultSet resultSet = statement.executeQuery(sql);
        if(resultSet.next()) {
            if (resultSet.getString(1).equals("1")) {
                logger.info("数据库存在！");
                flag = true;
            }
        }
        closeConnection(connection, statement, resultSet);
        return flag;
    }

    /**
     * 通过jdbc删除数据库
     * @param ip
     * @param pgPort
     * @param roleName
     * @param rolePw
     * @param dbName
     * @return
     * @throws SQLException
     */
    public static int dropDB(String ip, String pgPort, String roleName, String rolePw, String dbName) throws SQLException  {
        int flag = 1; // 1-删除失败，语句错误；2-删除失败，数据库不存在；3-删除成功
        logger.info("JDBC CREATE DB, conecting ip: " + ip);
        logger.info("JDBC CREATE DB, conecting port: " + pgPort);
        logger.info("JDBC CREATE DB, conecting rolename: " + roleName);
        logger.info("JDBC CREATE DB, conecting rolepw: " + rolePw);
        Connection connection = getConnection(ip, pgPort, roleName, rolePw);
        Statement statement = connection.createStatement();
        if (isDatabaseExisted(ip, pgPort, roleName, rolePw, dbName)) {
            String sql = "drop DATABASE " + dbName + ";";
            statement.execute(sql);

            if (!isDatabaseExisted(ip, pgPort, roleName, rolePw, dbName)) {
                flag = 3;
                logger.info("数据库删除成功！");
            }
        } else {
            logger.warn("数据库不存在，不可删除！");
            flag = 2;
        }
        closeConnection(connection, statement, null);
        return flag;
    }

    /**
     * 通过jdbc创建数据库
     * @param ip
     * @param pgPort
     * @param pgDatabaseReqVO
     * @return
     * @throws SQLException
     */
    public static int createDB(String ip, String pgPort, PgDatabaseReqVO pgDatabaseReqVO, String rolePw) throws SQLException {
        String roleName = pgDatabaseReqVO.getDbOwner();
        String dbName = pgDatabaseReqVO.getDbName();
        String encodeSet = pgDatabaseReqVO.getDbEncoding();
        String cType = pgDatabaseReqVO.getDbCtype();
        String collate = pgDatabaseReqVO.getDbCollate();
        String owner = pgDatabaseReqVO.getDbOwner();
        String sql = "CREATE DATABASE \"" + dbName + "\"" +
                " WITH OWNER '" + owner + "'";
        int flag = 1; // 1-创建失败，语句错误；2-创建失败，数据库已存在；3-创建成功
        logger.info("JDBC CREATE DB, conecting ip: " + ip);
        logger.info("JDBC CREATE DB, conecting port: " + pgPort);
        logger.info("JDBC CREATE DB, conecting rolename: " + roleName);
        logger.info("JDBC CREATE DB, conecting rolepw: " + rolePw);
        Connection connection = getConnection(ip, pgPort, roleName, rolePw);
        Statement statement = connection.createStatement();
        if (isDatabaseExisted(ip, pgPort, roleName, rolePw, dbName)) {
            logger.warn("数据库已存在，不可创建！");
            flag = 2;
        } else {
            if(!StringUtils.isBlank(encodeSet))
                sql = sql + " ENCODING '" + encodeSet + "'";
            if(!StringUtils.isBlank(collate))
                sql = sql + " LC_COLLATE '" + collate + "'";
            if(!StringUtils.isBlank(cType))
                sql = sql + " LC_CTYPE '" + cType + "'";
            sql = sql + ";";
            statement.execute(sql);

            if (isDatabaseExisted(ip, pgPort, roleName, rolePw, dbName)) {
                flag = 3;
                logger.info("数据库创建成功！");
            }
        }
        closeConnection(connection, statement, null);
        return flag;
    }

    /**
     * 通过jdbc创建用户
     * @param ip
     * @param pgPort
     * @param pgUser
     * @param pw
     * @param roleName
     * @param rolePw
     * @return
     * @throws SQLException
     */
    public static int createUser(String ip, String pgPort, String pgUser, String pw, String roleName, String rolePw) throws SQLException {
        int flag = 0; // 0-创建失败，节点为备库；1-创建失败，用户已存在；2-创建成功
        Connection connection = getConnection(ip, pgPort, pgUser, pw);
        Statement statement = connection.createStatement();
        Boolean flag1 = JDBCUtil.isPrimaryNode(ip, pgPort, pgUser, pw);
        Boolean flag2 = JDBCUtil.isUserExisted(ip, pgPort, pgUser, pw, roleName);
        if(flag1) {
            logger.info("该节点是主库.");
            if(!flag2) {
                String sql = "CREATE USER " + roleName + " CREATEDB CREATEROLE REPLICATION password \'" + rolePw + "\';";
                logger.info(JSON.toJSONString(statement.execute(sql)));
                flag2 = JDBCUtil.isUserExisted(ip, pgPort, pgUser, pw, roleName);
                if(flag2) {
                    logger.info("用户创建成功.");
                    flag = 2;
                }
            } else {
                flag = 1;
                logger.warn("用户已存在,不可创建！");
            }
        } else {
            flag = 0;
            logger.warn("该节点是备库，不可写！.");
        }
        closeConnection(connection, statement, null);
        return flag;
    }

    /**
     * 断开jdbc的连接
     * @param connection
     * @param statement
     * @param resultSet
     * @throws SQLException
     */
    private static void closeConnection(Connection connection, Statement statement, ResultSet resultSet) throws SQLException{
        if(connection != null)
            connection.close();
        if(statement != null)
            statement.close();
        if(resultSet != null)
            resultSet.close();
    }
}/* JDBCUtil output

 *///:~
```





### 2.3、连接pgpool

使用vip地址，端口是pgsql的端口



## 3、JDBC查询协议与pgSQL查询协议的区别

> 参考
>
> [PostgreSQL 前后端协议中的查询方式：Simple Query、Extended Query](https://www.cnblogs.com/kevinlucky/p/9984240.html)

