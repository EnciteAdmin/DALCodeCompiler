using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data.SqlClient;
using System.IO;

namespace DALCodeCompiler
{
    public class ReadSQL
    {
        public static string LoadSQLFile(string filename, string databaseName, string nameSpace) {
            string templateContent = File.ReadAllText(filename);
            templateContent = templateContent.Replace("{DatabaseName}", databaseName);
            templateContent = templateContent.Replace("{NameSpace}", nameSpace);
            return templateContent;
        }

        public static string GetPrimaryKeyScript(string TableName, string Schema)
        {
            StringBuilder sb = new StringBuilder();
            sb.AppendLine("SELECT COLUMN_NAME");
            sb.AppendLine("FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE");
            sb.AppendLine("WHERE OBJECTPROPERTY(OBJECT_ID(CONSTRAINT_SCHEMA + '.' + CONSTRAINT_NAME), 'IsPrimaryKey') = 1");
            sb.AppendLine("AND TABLE_NAME = '" + TableName + "' AND TABLE_SCHEMA = '" + Schema + "'");
            return sb.ToString();
        }

        public static string GetTablesScript()
        {
            StringBuilder sb = new StringBuilder();
            sb.AppendLine("SELECT table_name FROM information_schema.tables WHERE table_type = 'base table'");           
            return sb.ToString();
        }
    }
}
