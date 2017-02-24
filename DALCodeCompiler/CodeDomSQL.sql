DECLARE @ColName			nvarchar(500),
		@ColDataType		nvarchar(100),
		@ColCharMax			int

DECLARE @NameSpace nvarchar(500) = '{NameSpace}'

DECLARE	@TableType nvarchar(100),
		@TableName nvarchar(100),
		@PrimaryKeyID nvarchar(100),
		@PrimaryClass nvarchar(100)

DECLARE @Result nvarchar(max)
SET @Result = ''

SET		@TableType = 'BASE TABLE'	-- BASE TABLE | VIEW
SET		@TableName = '{TableName}'
SET		@PrimaryKeyID = '{PrimaryKeyID}'
SET		@PrimaryClass = '{PrimaryClass}'

DECLARE CCOLUMNS CURSOR FOR 
	SELECT	C.COLUMN_NAME,
			C.DATA_TYPE,
			C.CHARACTER_MAXIMUM_LENGTH
	FROM INFORMATION_SCHEMA.TABLES T
	INNER JOIN INFORMATION_SCHEMA.COLUMNS C ON T.TABLE_NAME=C.TABLE_NAME
		WHERE   T.TABLE_TYPE = @TableType
				AND T.TABLE_NAME = @TableName
				AND COLUMN_NAME NOT IN (
					'Enabled',
					'Created',
					'CreatedByUserID',
					'Modified',
					'ModifiedByUserID',
					'Deleted',
					'DeletedByUserID')
OPEN CCOLUMNS

SET @Result = @Result +	'using System;'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'using System.Collections.Generic;'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'using System.Data;'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'using SQL;'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'using SQLDAL;'+ CHAR(13)+CHAR(10)
SET @Result = @Result + 'using System.Configuration;'+CHAR(13)+CHAR(10)
SET @Result = @Result +	''+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'namespace ' + @NameSpace+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'{'+ CHAR(13)+CHAR(10)
SET @Result = @Result +   '    public class ' + @TableName + ' : ' + @PrimaryClass+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'        {'+ CHAR(13)+CHAR(10)

-- For each field, build the declarative
FETCH NEXT FROM CCOLUMNS INTO @ColName, @ColDataType, @ColCharMax
WHILE (@@FETCH_STATUS = 0)
BEGIN
	DECLARE @DataType nvarchar(100)
	SET  @DataType = CASE @ColDataType
						 WHEN 'tinyint' THEN 'int'
						 WHEN 'datetime' THEN 'DateTime'
						 WHEN 'money' THEN 'decimal'
						 WHEN 'int' THEN 'int'
						 WHEN 'bigint' THEN 'long'
						 WHEN 'bit' THEN 'bool'
						 WHEN 'image' THEN 'byte[]'
						 WHEN 'float' THEN 'double'
						 WHEN 'time' THEN 'TimeSpan'
						 WHEN 'decimal' THEN 'decimal'
						 WHEN 'real' THEN 'float'
						 ELSE 'string' END

	SET @Result = @Result +	'	        public ' + @DataType + ' ' + @ColName + ' { get; set; } // DB Data Type: ' + @ColDataType + '(' + CAST(ISNULL(@ColCharMax,'') as nvarchar) + ')'+ CHAR(13)+CHAR(10)
    FETCH NEXT FROM CCOLUMNS INTO @ColName, @ColDataType, @ColCharMax
END
CLOSE CCOLUMNS
DEALLOCATE CCOLUMNS
-- Build the base class information
SET @Result = @Result +	''
SET @Result = @Result +	'		    public ' + @TableName + '() {'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.thisTable = "' + @TableName + '";'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.thisKeyField = "' + @PrimaryKeyID + '";'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.cacheDuration = ConfigurationManager.AppSettings["cacheTimeout"].ToString();'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.connectionString = ConfigurationManager.ConnectionStrings["DataStore"].ConnectionString.ToString();'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.excludedFields = getExcludedFields();'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.userID = getUserID();'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.sql = new SQLLayer(this.connectionString, this.cacheDuration, this.userID, this.excludedFields);'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	        }'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	''+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	        public ' + @TableName + '(int UserID)'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'			{'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.thisTable = "' + @TableName + '";'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.thisKeyField = "' + @PrimaryKeyID + '";'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.cacheDuration = ConfigurationManager.AppSettings["cacheTimeout"].ToString();'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.connectionString = ConfigurationManager.ConnectionStrings["DataStore"].ConnectionString.ToString();'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.excludedFields = getExcludedFields();'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.userID = UserID;'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.sql = new SQLLayer(this.connectionString, this.cacheDuration, this.userID, this.excludedFields);'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'			}'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	''+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	        public ' + @TableName + '(SQLDAL.Data data, int UserID)'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'			{'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.thisTable = "' + @TableName + '";'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.thisKeyField = "' + @PrimaryKeyID + '";'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.cacheDuration = ConfigurationManager.AppSettings["cacheTimeout"].ToString();'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.connectionString = ConfigurationManager.ConnectionStrings["DataStore"].ConnectionString.ToString();'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.excludedFields = getExcludedFields();'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.userID = UserID;'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				this.sql = data.sql;'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'			}'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	''+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'			public DataTable GetDataTable(List<' + @TableName + '> listResults)'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'			{'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				DataTable dt = ListToDataTable.ToDataTable(listResults);'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				return dt;'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'			}'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	''+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	        public List<' + @TableName + '> LoadList()'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	        {'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	            object o = this;'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	            List<Object> listObjects = new List<Object>();'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	            List<' + @TableName + '> listResults = new List<' + @TableName + '>();'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	            List<SQLParameter> parameters = new List<SQLParameter>();'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	            sql.LoadList(ref listObjects, this, thisTable, parameters);'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	            foreach (var obj in listObjects)'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	            {'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	                ' + @TableName + ' thisObj = (' + @TableName + ')obj;'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	                listResults.Add(thisObj);'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	            }'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	            return listResults;'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	        }'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	''+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	        public List<' + @TableName + '> LoadListBy(string FieldName, string Condition, string Compare = "=")'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	        {'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	            object o = this;'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	            List<Object> listObjects = new List<Object>();'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	            List<' + @TableName + '> listResults = new List<' + @TableName + '>();'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	            List<SQLParameter> parameters = new List<SQLParameter>();'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'				parameters.Add(new SQLParameter { Field = FieldName, Value = Condition, Operation = Compare });'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	            sql.LoadList(ref listObjects, this, thisTable, parameters);'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	            foreach (var obj in listObjects)'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	            {'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	                ' + @TableName + ' thisObj = (' + @TableName + ')obj;'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	                listResults.Add(thisObj);'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	            }'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	            return listResults;'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	        }'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	    }'+ CHAR(13)+CHAR(10)
SET @Result = @Result +	'	}'+ CHAR(13)+CHAR(10)

SELECT @Result