--启动hive
输入命令 $HIVE_HOME/bin/hive --若$HIVE_HOME/bin已经添加到环境变量PATH,则只需要输入hive命令
    输出 hive> 提示符表示已进入hive

	
set 命令显示或修改变量值
	set 显示hivevar的所有变量
	set -v 显示hivevar和hadoop所定义的所有变量或属性
	set var 显示变量的值
	set var=value 设置变量
	--hivevar  定义变量  
	--hiveconf //set --hiveconf hive.cli.print.current.db=true 设置"hive>"提示符中间打印当前数据库名
	         --//set hive.cli.print.header=true 打印出字段名称，可以在-i选项的初始化文件中添加
	
	
hive的bash shell 命令行CLI界面选项  //在shell命令行中而不是在"hive>"提示符中
$ hive
	   -d --define  //定义变量
	   -S  //安静模式，可以去掉"ok" "Time taken" 等无关紧要的输出信息
	   -h  //链接远程主机名
	   -f  //hql脚本文件   $ hive -f /path/query.hql
	   	也可以在"hive >"提示符中:hive > source /path/query.hql;
	   -i  //初始化hql脚本文件 //即在cli打开 "hive >"提示符出现前执行的文件，可以将需要频繁执行的命令或设置增加到这个文件,
								 一般是.hiverc文件
	   						     例如增加"set --hiveconf hive.cli.print.current.db=true;"
	   -p  //端口
	   -e --即可以直接在shell命令行而不需要进入"hive>"命令行就可以执行hive命令/hql,命令和hql需要用双引号引起来
	   	//[root@hostname:/home/user]$ hive -S -e "select * from tab_name" > test.txt
									  hive -S -e "set"|grep "xxx"  //过滤某个属性或变量
									  
hive shell //即"hive >"提示符，可以执行简单的bash shell命令，只需要在命令前加上感叹号"!"并以分号";"结尾
		   //不支持交互命令，不支持管道，不支持自动补全，"! ls *.hql;"表示查找"*.hql"一个文件，而不是所有文件
hive > ! pwd;  打印当前hive的路径

hive执行hadoop的dfs命令  //hadoop命令在bash shell执行格式:hadoop fs -ls
hive > dfs -ls /home/user;


数据类型
	基础数据类型:tinyint
				 smalint
				 int
				 bigint
				 boolean
				 float
				 double
				 string
				 timestamp
				 binary
	集合数据类型:
				 struct //field_name struct<street:string,city:string,state:string,zip:int> 一个字段值中包含多个结构的值
				 map  //键值对类型: field_name map<string,float> 键string,值float 
				 array  //一维数组，下标从0开始
	create table db_name.employess(
		name        string comment 'employee name',
		salay       float comment 'salay',
		subordinates array<string>,
		deductions	 map<string,float>,
		address	     struct<street:string, city:string, state:string, zip:int>
	)	
	row format delimited 
	fields terminated by '001'             --001显示  ^A   
	collection items terminated by '002'   --002 显示 ^B
	map keys terminated by '003'           --003 显示 ^C   都是默认分隔符
	comment 'description of table'
	TABPROPERTIES('CREATOR'='lanny',...)
	location '/user/hive/warehouse/db_name.db/employess'
	--lines terminated by '\n'  默认
	--stored as textfile        默认
	;
	

读时模式
hive在数据文件生成时不会像传统数据库那样对字段的约束进行检验，而是在查询时:如文件中的字段少于select的字段，则显示null,
若文件中的字段多于select的字段，则无影响，若int型的字段插入的是string型的数据，则显示null
	

数据定义
hive不支持行级增删改，不支持事务。
hive中数据库的概念仅仅是表的一个目录或命名空间(父目录)，这对于有很多组和用户的大集群来说可以避免表命名的冲突。	
	//default数据库没有自己的目录
hql相对的与mysql语法最接近
	hive > show database; 显示hive包含的数据库
		 > show database like 'h.*'; 显示所有已字母开头的数据库
		 
		 > create database if not exists db_name; 创建数据库db_name,
		  //数据库目录默认在属性hive.metastore.warehouse.dir下,即db_name数据库目录为$hive.metastore.warehouse.dir/db_name.db
		 >create database db_name
		  location '/home/mydir'  指定数据库目录
		  comment 'db_name info' 增加描述信息 
		  with DBPROPERTIES('creator'='lanny','date'='2022-01-01'); --增加相关的键-值对属性
		 
		 > describe database db_name; 显示某个数据库信息
		 > describe database extended db_name; 显示'with DBPROPERTIES'属性信息需要加上extended
		 
		 > use db_name; 使用db_name为当前工作数据库
			--set hive.cli.print.current.db=true; 在'hive >'提示符中间显示数据库名
		 > drop database if exists db_name cascade; 只有加上cascade才可以删除还有表的数据库
		 > alter database db_name set DBPROPERTIES('modify-by'='lanny'); 只能修改数据库的描述信息，其他元数据不可修改
		 
		 > show tables ['h.*']; 显示当前数据库下所有的表,可选项正则表达式['h.*']
		 > show tables in db_name; 指定展示某个数据库的表
		 
		 > describe extended/formatted db_name.tab_name; 显示或格式化显示表的信息，可以查看是否为外部表及分区键
		 > describe tab_name.name; 显示列name的信息
		 > describe extended tab_name partiton(field=2022);这个语句才能看到外部分区表分区目录的具体路径
		 
		 > create external table extended_tab_name(  --创建外部表
		   id string,
		   name string
		   )
		   row format delimited
		   fields terminated by ','
		   location '/data/path';   --指定外部表的数据所在位置，创建外部分区表可以不指定location
		 --创建外部表和内部表都可以指定位置或不指定位置，若不指定目录则都会在默认的目录下创建表目录，
		 --若指定目录则网页上显示的都是指定的目录。
		 
		 > create [external] table tab_name like tab_name1 [location '/data/path']; 根据源表属性复制表结构
		 
		 > create table tab_name(  --创建分区表
		 id string,
		 name string
		 )
		 partitioned by(country string,state string);
		 
		 > show partitons tab_name; 显示表的所有分区
		 > show partitions tab_name partiton(field='value');显示某个分区字段值下的所有分区
		 
		 > load data local inpath '/data/path/test.txt' into table tab_name
		   partiton(field1=value1,field2=value2);  --管理表不是分区表时可以这样添加分区
		   
		 > alter table tab_name add partiton(field=value1,field=value2)
		   location '/data/path'; --管理表和外部表的分区表都可以用这个语句添加分区并指定路径 
								  --//管理表指定的路径可以不是hive warehouse下的目录
								  --可以同时添加多个分区
		 > alter table tab_name partition(field=value1)
		   set location '/data/path_bak'; 修改分区的数据位置，但是原数据不会删除也不会移动
		   
		 > create table tab_name (  --创建分桶表
		   id   int,
		   name string
		   )
		   partitioned by(date string)
		   clustered by(id) into 96 buckets
		   row format delimited
		   fields terminated by ',';
		 > set hive.enforce.bucketing=true; 需先设置属性初始化一个正确的reduce个数
	 
		 > alter table tab_name rename to tab_name1; 重命名表
		 > alter table tab_name change column col_old col_new int comment 'xxx'
		   [after other_col][first]; 重命名字段，并修改数据的位置(修改位置后需要注意是否和数据文件中的数据类型匹配)
		 > alter table tab_name add columns col1 int  comment 'xxx'; 添加字段
		 > alter table tab_name set tabproperties('notes'='xxx'); 增加或修改表属性，不能删除
		 
		 --这两个语句只能应用在分区表中
		 > alter table tab_name partition(field=value1) enable[disable] no_drop; 分区不能被删除
		 > alter table tab_name partition(field=value1) enable[disable] offline; 分区不能被查询
		 
		 
数据操作
装载数据
	> load data local inpath '/data/path'
	  overwrite into table tab_name
	  partition(field=value); 覆盖插入管理分区表数据，
							//如果没有overwrite关键字即追加数据时，若有同名文件则新追加的文件会在文件名后加上'_序列号'
insert插入数据
	> insert overwrite/into table tab_name partition(field=value)
	  select * from tab_name_bak where field=value;
	> from tab_name_bak a
	  insert into table tab_name1 
		select * where a.field=value
	  insert overerite table tab_name2 partition(field=value) s
		elect * where a.field=value
	  ; 一次插入多个表(分区)，可以混合使用
	  > create table tab_name as select * from tab_name_bak;仅限管理表
动态分区插入
	> set hive.exec.dynamic.partiton=true; 开启动态分区，默认是false
	> set hive.exec.dynamic.partiton.mode=nonstrict; 动态分区模块为非严格的，默认为strict,需要在第一个字段设置静态分区值
	> insert overerite table tab_name partiton(country,state)
	  select b.id,b.name,b.country,b.state from tab_name_bak b;
	  //select字句最后的字段必须对应目标表的分区字段	
	  //load 命令不支持动态分区插入
	
导出数据
	$ hadoop fs -cp source_file dest_file;在bash shell命令行直接复制文件就行，适用于源文件和目标文件期望的格式一样。
	
	> insert overwrite local directory '/tmp/data/path'
	  select * from tab_name; 导出到目录 '/tmp/data/path'
	> from tab_name a
	  insert overwrite local directory '/path1'
		select * where a.field=value1
	  insert overwrite local directory '/path2'
		select * where a.field=value2
	  ;一次输出到多个文件
	
	
hql查询
(集合的字符串元素被双引号引起来)
数组类型字段显示:中括号[]括起来，以逗号分隔，值被双引号引起来; ["aa","bb",...]
map类型字段显示:大括号{}引起来{"guoshui":0.2,"dishui":01,...}
struct类型字段显示:和map一样{"street":"二号大街","city":"shenzhen","provience":"guangdong","zip":"0755"}
	> select name, subordinates[0] from emoloyees; 数组的第一个元素
	> select name, dedcutions["State Taxes"] from employees; map键"State Taxes"的值
	> select name, address.city from employees; struct中city元素的值
	
	> select name,`price.*` from employees; 所有以price开头的列，(使用正则表达式)
	
	> set hive.map.aggr=true; 设置属性提高聚合的性能，但是需要更多内存
	
	> select count(distinct col) from employees;如果col为分区字段，则count为0，因为分区字段的值都命名为了目录名，不在文件里
	
	> 需要特别注意浮点数的比较，避免数字从窄的数据类型隐式转换到宽的数据类型
	  employees表中dedcution{key string,val float}
	  select * from employees where dedcution[key]>0.2;当key对应的val也等于0.2时，这一条记录在这个where条件仍然为真，
	  即... where dedction[key]=0.2>0.2为真，因为数字0.2不能够使用float或double准确表示，0.2会转换成0.200000001，
	  而dedcution[key]的值也会由float转换为double型变成0.20001000，因此...where dedcution[key]>0.2为真，可以用
	  ...where dedcution[key]>cast(0.2 as float)解决
	  
	> select * from employees where address.street rlike '.*(shenzhen|guangzhou).*'; 街道名称中包含shenzhen或guangzhou,

hive只能等值连接
	> select * from a join b on a.id=b.id
					  join c on a.id=b.id;
	  --hive连接顺序总是从左到右，因此应把小表放在左边；
	  --每个Join都会开启一个mapreduce任务，但是如果Join字段相同，则只会开启一个mapreduce
	> select /*+streamtable(a)*/ * from a join b on a.id=b.id; 
	  --显示告诉优化器a表为大表(stream表)，即使它出现在左边也不会先执行
hive不支持in、exists字句，但可以用左半连接left semi join达到同样目的
	> select a.* from a left semi join b on a.id=b.id
	  where a.name like '%bob%'; 左半连接select/where字句中都不能出现右边表的字段
	  
map side join优化(不支持右连接和全连接)
	当连接中只有一张表是小表的话，可以放进内存在map端执行连接，因而省略了reduce步骤
	> set hive.auto.convert.join=true; 启动优化，默认为false
	> set hive.mapjoin.smalltable.filesize=25000000(默认值,单位字节);设置能够使用这种优化的小表的大小
	> select /*+mapjoin(a)*/ * from a join b on a.id=b.id; 这种方式v0.7版本后已经不用，不过如果加上也有效
	
	当都是大表，表中的数据是按照连接键进行分桶的，且一个表的分桶个数是另一个表分桶个数的若干倍，那么也可以在
	map阶段按照分桶数据进行连接
	> set hive.optimize.bucketmapjoin=true;

--sort merge join(待续)

	> select * from employees order by name; //order by 全局排序,只会在一个reduce任务中执行，如果数据量大应避免
	> select * from employees sort by name; //sort by在每个reduce任务中排序，但是reduce合并后的全局并不是有序的，
	  //并且不同的reduce中可能会有相同的键-值对，会造成相同的记录在上下文中的多个地方出现(重叠)
	> select * from employees distribute by name,sort by name,address; //distribute by把map输出的键-值对按哈希值相同的键
	  //都输出到一个reduce中，再进行排序，即保证了不会出现重叠，(全局有序仍然有疑问)
	> select * from employees cluster by name; //如果distribute by和sort by的字段完全一样且是升序排列，那么可以用cluster by代替

	> select * from employees tablesample(bucket 2 out of 4 on name) a; 抽样查询(分桶)
	  //以name分成4个桶取第2个桶的数据。需注意创建表时如果分了桶，那么此时分桶的个数应为建表分桶个数的整数倍。
	> select * from employees tablesample(0.1 percent) a; 抽样查询(分块)
	  //基于行、按照数据块的百分比抽样，如果数据块小于HDFS的数据块单元，则会返回所有行


调优
limit限制:
	> select * from employees limit 10; limit仍然会扫描所有的数据再返回部分数据
	> set hive.limit.optimize.enable=true; 设置属性进行抽样，不会扫描整个表
	> set hive.limit.row.max.size=100000; 设置limit最大限制的行数
	> set hive.limit.optimize.limit.file=10; 设置最大采样的文件数
	--这个限制属性有个缺点，就是有用的数据可能不会被查询到

join优化
对于小表放在左边，或使用/*+streamtable(big_table)*/显示提示大表;
map side join优化(在232行)

本地模式
当hive的输入数据非常小时，为了查询触发mapreduce任务的时间可能比实际job执行的时间要多得多，因此此时可以通过本地模式
在单台机器上(或单个进程中)处理所有任务。
	> set hive.exec.mode.local.auto=true; 设置让Hive在适当的时候自动启动这个优化
	//通常可以将这个配置写入$HOME/.hiverc文件。

fetch //在全局查找、字段查找、limit查找等都不走mapreduce。例如：SELECT * FROM employees;在这种情况下，Hive可以简单
地读取employee对应的存储目录下的文件，然后输出查询结果到控制台。
	> set hive.fetch.task.conversion=more; 默认是none

并行执行
hive默认情况下一次只能执行一个阶段，比如mapreduce阶段、抽样阶段、合并阶段、limit阶段，但有时候一个Job中的阶段并不是
互相依赖，所以此时可以并发执行。
	> set hive.exec.parallel=true;

严格模式
可以防止用户执行那些意想不到的不好的影响的查询。
其一：对于分区表，分区表目录下有大量文件，所以必须在where条件上加上分区字段值进行过滤，避免扫描所有文件并开启大量任务
其二：对于order by字句，必须加上Limit限制，因为Order by是在一个reduce任务上执行，数据量大的话会非常慢
其三：限制执行笛卡尔积的查询
	> set hive.mapred.mode=strict;

调整mapper和reducer的个数(待续)

JVM重用
JVM重用是hadoop调优参数的内容，其对hive的性能具有非常大的影响，特别是对于很难避免小文件的场景或task任务特别多的场景，
hadoop默认配置是使用派生JVM来执行map和reduce任务，这时JVM启动过程会造成相当大的开销，尤其是执行的job包含成百上千个task任务。
JVM重用可以使得JVM实例在同一个job中重新使用N次，N的值在hadoop的mapred-site.xml($HADOOP_HOME/conf目录下)文件中设置。
但是JVM重用也有一个缺点，因为重用会一直占用map或reduce的资源，如果存在数据倾斜，只有一个reduce任务还在执行，其他任务
都执行完了，其他任务的资源仍然不会释放，直到所有任务完成才会释放。

...



Streaming --using可以使用linux命令或shell、pyhton等编程脚本执行对字段的转化，相当于替换编写UDF/UDAF/UDTF
	> select transform(old_column1,old_column2)
	  using '/bin/sed s/hehe/haha/g' as (new_column1 int,new_column2 string)
	  //using 'sh /path/script.sh' as (xxx)
	  from emplyoees;




hive --help --service cli   hive命令行服务帮助信息

hive 变量 (可用于在查询语句中，相当于sql server/oracle的declare)
hive --define或者hivevar  hive用户自定义变量
	hive --define var='hello world' 定义变量var=hello world
	set var; >>var=hello world  打印变量var
	或者
	set hivevar:var=1024;
	set hivevar:var; >>hivevar:var=1024
	
hive --hiveconf hive配置属性(变量)
	hive --hiveconf hive.cli.print.current.db=true  设置属性hive.cli.print.current.db=true (此属性默认为false)
	
hive system java系统的的属性
	set system:user.name; >>system:user.name=myname
	
hive env shell的环境变量
	set env:HOME; >>env:HOME=/home/myname
	
system和env设置变量时都需要指冒号：前缀

hive -e 引用sql语句,即引用的语句前可以有其他hive命令

hive -S 静默模式,可将select查询之外的信息屏蔽


分区表和数据产生关联的三种方式
一、上传数据后修复   --执行修复命令 msck repair table table_name;
1)创建分区目录
dfs -mkdir -p /user/hive/warehouse/ylj_db.db/stu_part/month=201906;
2)上传数据
dfs -put /opt/module/hive-1.2.1/datas/stu_part/20190601.txt /user/hive/warehouse/ylj_db.db/stu_part/month=201906;
3)查询数据
刚上传的数据查询不到，因为没有对应的元数据信息。
4)执行修复命令
hive (ylj_db)> msck repair table stu_part;
	hive (ylj_db)> select * from stu_part where month='201906';
	OK
	stu_part.id     stu_part.name   stu_part.month
	1       zhangsan        201906
	2       lisi    201906
	3       houzi   201906
	4       tuzi    201906
	Time taken: 0.147 seconds, Fetched: 4 row(s)
二、上传数据后添加分区
:重复方案一中的前两个步骤
3)添加分区
alter table stu_part add partition(month='201907');
4)查询数据
hive (ylj_db)> select * from stu_part where month='201907';
OK
三、创建文件夹后load数据到分区
1)创建分区目录
dfs -mkdir -p /user/hive/warehouse/ylj_db.db/stu_part/month=201908;
2)load上传数据
load data local inpath '/opt/module/hive-1.2.1/datas/stu_part/20190801.txt' into table stu_part partition(month='201908');
3)查询数据
hive (ylj_db)> select * from stu_part where month='201908';
OK


from source_table
	insert overwrite dest_table1
		partition(partition_field='vaule')
		select * where partition_field='value'
	insert overwrite dest_table2
		partition(partition_field='vaule')
		select * where partition_field='value'
	insert overwrite dest_table1
		partition(partition_field1='vaule')
		select * where partition_field='value'





		








