using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SQL;
using SQLDAL;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using System.Diagnostics;
using System.IO;
using Microsoft.CodeAnalysis.CSharp.Syntax;
using Microsoft.CodeAnalysis.Emit;

namespace DALCodeCompiler
{
    public class SQLClassStructure
    {
        public string Name;
        public string ClassData;
    }

    public class Program
    {
        public string scriptFile = "";
        public string nameSpace = "";
        public string databaseConnection = "";
        public string databaseUserID = "";
        public string databasePassword = "";
        public string databaseName = "";
        public string databaseSchema = "dbo";
        public string baseClass = "Data";
        public string targetPath = "";
        public string scriptTemplate = "";

        public List<SQLClassStructure> SQLClasses = new List<SQLClassStructure>();

        static void Main(string[] args)
        {
            Program program = new Program();
            program.DoScripting(args);
        }

        public void DoScripting(string[] args)
        {
            Console.WriteLine("Virvent Database Code Generator Version 1.0");
            foreach (var arg in args)
            {
                char[] s = { '-' };

                string[] thisArg = arg.Split(s);
                switch (thisArg[0])
                {
                    case "db":
                        databaseConnection = thisArg[1];
                        break;
                    case "dn":
                        databaseName = thisArg[1];
                        break;
                    case "ns":
                        nameSpace = thisArg[1];
                        break;
                    case "s":
                        scriptFile = thisArg[1];
                        break;
                    case "u":
                        databaseUserID = thisArg[1];
                        break;
                    case "p":
                        databasePassword = thisArg[1];
                        break;
                    case "sc":
                        databaseSchema = thisArg[1];
                        break;
                    case "bc":
                        baseClass = thisArg[1];
                        break;
                    case "t":
                        targetPath = thisArg[1];
                        break;
                    default:
                        break;
                }

                Console.WriteLine(thisArg[0] + " value = " + thisArg[1]);
            }
            Console.WriteLine("Starting compiler");

            // connect to database
            string ConnectionString = "Data Source=" + databaseConnection + ";Initial Catalog=" + databaseName + ";Persist Security Info=True;User ID=" + databaseUserID + ";Password=" + databasePassword + ";";
            Console.WriteLine("Connecting to database " + databaseConnection + "." + databaseName);
            SQL.SQLLayer sqlLayer = new SQL.SQLLayer(ConnectionString, "10");
            sqlLayer.GetConnection();
            Console.WriteLine("Loading database script");
            scriptTemplate = ReadSQL.LoadSQLFile(scriptFile, databaseName, nameSpace);

            // loop and build table-specific scripts
            sqlLayer.BuildCommand(ReadSQL.GetTablesScript());
            sqlLayer.Command.CommandType = System.Data.CommandType.Text;
            sqlLayer.FillDataReader();

            List<string> TableNames = new List<string>();
            while (sqlLayer.DataReader.Read())
            {
                TableNames.Add(sqlLayer.DataReader[0].ToString());
                Console.WriteLine("Found table " + sqlLayer.DataReader[0].ToString());
            }
            sqlLayer.DataReader.Close();

            foreach (var table in TableNames)
            {
                // get primary key
                sqlLayer.BuildCommand(ReadSQL.GetPrimaryKeyScript(table, databaseSchema));
                sqlLayer.Command.CommandType = System.Data.CommandType.Text;
                sqlLayer.FillDataReader();
                var primaryKey = "ID";

                if (sqlLayer.DataReader.HasRows)
                {
                    sqlLayer.DataReader.Read();
                    primaryKey = sqlLayer.DataReader[0].ToString();
                }
                else
                {
                    Console.WriteLine("Unable to find primary key for " + table + ". Using default of ID");
                }
                sqlLayer.DataReader.Close();

                string tmpTemplate = scriptTemplate;
                tmpTemplate = tmpTemplate.Replace("{TableName}", table);
                tmpTemplate = tmpTemplate.Replace("{PrimaryKeyID}", primaryKey);
                tmpTemplate = tmpTemplate.Replace("{PrimaryClass}", baseClass);

                sqlLayer.BuildCommand(tmpTemplate);
                sqlLayer.Command.CommandType = System.Data.CommandType.Text;
                sqlLayer.FillDataReader();
                if (sqlLayer.DataReader.HasRows)
                {
                    sqlLayer.DataReader.Read();
                    SQLClasses.Add(new SQLClassStructure { Name = table, ClassData = sqlLayer.DataReader[0].ToString() });
                    Console.WriteLine("Class prepared for table " + table);
                }
                else
                {
                    Console.WriteLine("Unable to create class for " + table + ".");
                }
                sqlLayer.DataReader.Close();
            }

            // loop through the scripts and turn these into actual classes.
            // this is the REALLY badass part
            foreach (SQLClassStructure ClassName in SQLClasses)
            {
                Console.WriteLine("Creating Class Library for table " + ClassName.Name);

                using (StreamWriter writer = File.CreateText(targetPath + "\\" + ClassName.Name + ".cs"))
                {
                    writer.WriteLine(ClassName.ClassData);
                }

                //var tree = CSharpSyntaxTree.ParseText(ClassName.ClassData);

                //SyntaxNode oldRoot = tree.GetRoot();
                //var rewriter = new ConsoleWriteLineInserter();
                //SyntaxNode newRoot = rewriter.Visit(oldRoot);
                //newRoot = newRoot.NormalizeWhitespace(); // fix up the whitespace so it is legible.
                //var newTree = SyntaxFactory.SyntaxTree(newRoot, path: "MyCodeFile.cs", encoding: Encoding.UTF8);
                //var compilation = CSharpCompilation.Create("MyCompilation")                    
                //    .AddReferences(MetadataReference.CreateFromFile(ClassName.Name + ".cs"))
                //    .AddSyntaxTrees(newTree);

                //string output = Execute(compilation);
                //Console.WriteLine(output);
            }
            Console.ReadLine();
        }

        public string Execute(Compilation comp)
        {
            var output = new StringBuilder();
            string exeFilename = baseClass+".dll", pdbFilename = baseClass+".pdb", xmlCommentsFilename = baseClass+".xml";
            EmitResult emitResult = null;

            using (var ilStream = new FileStream(exeFilename, FileMode.OpenOrCreate))
            {
                using (var pdbStream = new FileStream(pdbFilename, FileMode.OpenOrCreate))
                {
                    using (var xmlCommentsStream = new FileStream(xmlCommentsFilename, FileMode.OpenOrCreate))
                    {
                        // Emit IL, PDB and xml documentation comments for the compilation to disk.
                        emitResult = comp.Emit(ilStream, pdbStream, xmlCommentsStream);
                    }
                }
            }

            if (emitResult.Success)
            {
                var p = Process.Start(
                    new ProcessStartInfo()
                    {
                        FileName = exeFilename,
                        UseShellExecute = false,
                        RedirectStandardOutput = true
                    });
                output.Append(p.StandardOutput.ReadToEnd());
                p.WaitForExit();
            }
            else
            {
                output.AppendLine("Errors:");
                foreach (var diag in emitResult.Diagnostics)
                {
                    output.AppendLine(diag.ToString());
                }
            }

            return output.ToString();
        }

    }

    // Below CSharpSyntaxRewriter inserts a Console.WriteLine() statement to print the value of the
    // LHS variable for compound assignement statements encountered in the input tree.
    public class ConsoleWriteLineInserter : CSharpSyntaxRewriter
    {
        public override SyntaxNode VisitExpressionStatement(ExpressionStatementSyntax node)
        {
            SyntaxNode updatedNode = base.VisitExpressionStatement(node);

            if (node.Expression.Kind() == SyntaxKind.AddAssignmentExpression ||
                node.Expression.Kind() == SyntaxKind.SubtractAssignmentExpression ||
                node.Expression.Kind() == SyntaxKind.MultiplyAssignmentExpression ||
                node.Expression.Kind() == SyntaxKind.DivideAssignmentExpression)
            {
                // Print value of the variable on the 'Left' side of
                // compound assignement statements encountered.
                var compoundAssignmentExpression = (AssignmentExpressionSyntax)node.Expression;
                StatementSyntax consoleWriteLineStatement =
                    SyntaxFactory.ParseStatement(string.Format("System.Console.WriteLine({0});", compoundAssignmentExpression.Left.ToString()));

                updatedNode =
                    SyntaxFactory.Block(SyntaxFactory.List<StatementSyntax>(
                                            new StatementSyntax[]
                                            {
                                            node.WithLeadingTrivia().WithTrailingTrivia(), // Remove leading and trailing trivia.
                                            consoleWriteLineStatement
                                            }))
                        .WithLeadingTrivia(node.GetLeadingTrivia())        // Attach leading trivia from original node.
                        .WithTrailingTrivia(node.GetTrailingTrivia());     // Attach trailing trivia from original node.
            }

            return updatedNode;
        }

        // A simple helper to execute the code present inside a compilation.
    }
}