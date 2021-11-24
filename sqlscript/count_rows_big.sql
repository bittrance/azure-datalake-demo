select count(*)
from openrowset(
   bulk 'https://bittrancedatalakedemo.dfs.core.windows.net/big-data/big-set/',
   format = 'csv',
   fieldterminator ='0x0b',
   fieldquote = '0x0b',
   rowterminator = '0x0a'
    ) with (doc nvarchar(max)) as rows
    cross apply openjson(doc, '$') with ("id" varchar(20))
