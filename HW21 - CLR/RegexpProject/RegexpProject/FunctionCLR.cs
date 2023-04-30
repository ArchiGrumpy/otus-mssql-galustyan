using Microsoft.Analytics.Interfaces;
using Microsoft.Analytics.Interfaces.Streaming;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using System.Text.RegularExpressions;
using System.Data;

namespace RegexpProject
{
    public static class FunctionsCLR
    {
        [SqlFunction(IsDeterministic = true)]
        public static SqlBoolean IsMatch(SqlString str, SqlString pattern)
        {
            var reg = new Regex(pattern.ToString());
            return (SqlBoolean)reg.IsMatch(str.ToString());
        }

    }
}