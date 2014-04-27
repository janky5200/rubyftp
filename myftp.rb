# encoding: utf-8
require "net/ftp"
VERSION = "1.0"
@@default_init = {"host" => "www.test.com",
              "port" => "21",
              "ignore" => "ftp.ini,.svn,.git,._*",
              "username" => "ftp" ,
              "password" => "password",
              "code" => "svn",
              'ftp_base_path' =>'./'
              
};
#打印文件
def putsinit
  @@default_init.each do |key,value|
       # ... process the file
    puts "#{key}=#{value}";
  end
end
#把默认配置写到当前目录
def initdefault
  File.open("./ftp.ini","w+") do |file|
    @@default_init.each do |key,value|
       # ... process the file
       if key == 'code'
          file.write("#{key}=#{value}    只支持git 和svn\n");
       else
          file.write("#{key}=#{value}\n");
       end
    end
  end
end
#从文件读取配置
def reset_init
  File.open("./ftp.ini", "r") do |file|
     # ... process the file
      file.readlines.each  do |line|
        keyvalue = line.split('=');
        if keyvalue.length!=2
          puts "文件格式不正确";
          return
        end
        @@default_init[keyvalue[0].strip] =  keyvalue[1].strip
      end
  end
end
def eachfile (thispath,mt)
  Dir.foreach(thispath) do |entry|
 
    if entry != ".." && entry != "." && entry != "./"
      mt[File.absolute_path(entry,thispath)];
      if(File.directory?(thispath + "/"+ entry))
         eachfile thispath + "/"+  entry,mt
      end
    end

  end
end

def sendfile (thispath,ftp) #发送文件到ftp
  Dir.foreach(thispath) do |entry|
    if entry != ".." && entry != "." && entry != "./"
      canupload = true;
      if  !@@default_init['ignore'].empty?
        @@default_init['ignore'].split(',').each do |str|
          if entry.downcase  == str.downcase  || File.extname(entry).downcase  == str.downcase 
              canupload = false;
            end
          end
      end

      if canupload
        if(File.directory?(thispath + "/"+ entry))
          begin
            ftp.mkdir(entry);
            rescue Net::FTPPermError =>ex
          end
          puts "创建目录#{entry}";
          ftp.chdir(entry);
          sendfile(thispath + "/"+  entry,ftp);
          ftp.chdir('../');
        else
          puts "上传文件#{File.absolute_path(entry,thispath)}";
          ftp.put(File.absolute_path(entry,thispath));
        end
      end
      
    end

  end
end
if $*.length
  if $*[0] == 'h'
    #File.new
    puts "参数 i 生成一个默认配置文件";
     exit;
  elsif $*[0] == 'i'
    initdefault;
    puts "已经生成配置文件, ftp.ini";
    exit;
  end
  
end

if File.exists?("./ftp.ini")
  reset_init

 # putsinit
else
  puts "找不到配置文件,请将配置文件放到要上传的目录";
  exit;
end
update = false;
  if @@default_init["code"] == "svn"
    update = system("svn update");
  elsif @@default_init["code"] == "git"
    update =  system("git pull");
  else
    puts "找不到代码版本管理器";
  end
if update == false
  puts "更新失败!";
  
end
puts '正在连接服务器...'
#eachfile('./',Proc.new {|filename| puts filename;});
Net::FTP.open(@@default_init['host']) do |ftp| #开通ftp
  puts "正在登陆";
  ftp.login(@@default_init['username'],@@default_init['password']);
  #files = ftp.chdir('pub/lang/ruby/contrib')
  puts "登陆成功";
   puts "开始上传文件";
  files = ftp.chdir(@@default_init['ftp_base_path']);
  
  sendfile './',ftp;
  

  puts "文件上传成功";
end