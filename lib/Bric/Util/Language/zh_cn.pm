package Bric::Util::Language::zh_cn;

=head1 NAME

Bric::Util::Language::zh_cn - Bricolage 簡体中文翻译

=head1 VERSION

$LastChangedRevision$

=cut

our $VERSION = (qw$Revision: 1.16 $ )[-1];

=head1 DATE

$LastChangedDate$

=head1 SYNOPSIS

In F<bricolage.conf>:

  LANGUAGE = zh_cn

=head1 DESCRIPTION

Bricolage 簡体中文翻译.

=cut

use constant key => 'zh_cn';

our @ISA = qw(Bric::Util::Language);

our %Lexicon =
    (
     # Date
     'Jan' => '一月' ,
     'Feb' => '二月' ,
     'Mar' => '三月' ,
     'Apr' => '四月' ,
     'May' => '五月' ,
     'Jun' => '六月' ,
     'Jul' => '七月' ,
     'Aug' => '八月' ,
     'Sep' => '九月' ,
     'Oct' => '十月' ,
     'Nov' => '十一月' ,
     'Dec' => '十二月' ,
     'Day' => '日' ,
     'Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec' => '一月 二月 三月 四月 五月 六月 七月 八月 九月 十月 十一月 十二月' ,
     'Month' => '月' ,

     # Time
     'Date' => '日期' ,
     'Hour' => '时' ,
     'Minute' => '分' ,
     'Second' => '秒' ,

     # Expiries
     '1 Day' => '一天' ,
     '3 Days' => '三天' ,
     '5 Days' => '五天' ,
     '10 Days' => '十天' ,
     '15 Days' => '十五天' ,
     '20 Days' => '二十天' ,
     '30 Days' => '三十天' ,
     '45 Days' => '四十五天' ,
     '90 Days' => '九十天' ,
     '180 Days' => '一百八十天' ,
     '1 Year' => '一年' ,

     # Priotity
     'High' => '最高' ,
     'Low' => '最低' ,
     'Medium High' => '较高' ,
     'Medium Low' => '较低 ' ,
     'Normal'  => '正常',

     # Areas
     'Alert Type Manager' => '警告类型管理员' ,
     'Category Manager' => '分类管理员' ,
     'Contributor Type Manager ' => '供稿者类型管理员' ,
     'Current Output Channels' => '目前采用的输出频道员' ,
     'Destination Manager' => '发布目标管理员' ,
     'Element Manager' => '元素管理员' ,
     'Element Type Manager' => '元素类型管理员' ,
     'Group Manager' => '群组管理员' ,
     'Job Manager' => '工作管理员' ,
     'Manager' => '管理员' ,
     'Media Gallery' => '媒体艺廊' ,
     'Media Type Manager' => '媒体类型管理员' ,
     'Preference Manager ' => '偏好管理员' ,
     'Source Manager ' => '来源管理员' ,
     'Source Manager' => '来源管理员' ,
     'User Manager' => '使用者管理员' ,
     'Workflow Manager ' => '流程管理员' ,
     'Workflow Manager' => '流程管理员' ,
     'Workspace for [_1]' => '[_1] 的工作区' ,

     # Interface Objects
     'Checkbox' => '核选框' ,
     'Columns' => '直栏' ,
     'Custom Fields' => '自订字段' ,
     'Page' => '页' ,
     'Pulldown' => '摺叠式' ,
     'Radio Buttons' => '多选一选项' ,
     'Rows' => '横列' ,
     'Size' => '大小' ,
     'Template' => '模板' ,
     'Text Area' => '文字区域' ,
     'Workflows' => '流程' ,
     'Workflow' => '流程' ,
     '[_1] Field Text' => '[_1] 字段文字' ,

     # General Information
     '&quot;Story&quot;' => '&quot;稿件&quot;' ,
     '&quot;Template&quot;' => '&quot;模板&quot;' ,
     'ADMIN' => '管理' ,
     'ADVANCED SEARCH' => '进阶搜寻' ,
     'Actions' => '行动' ,
     'Active' => '起用' ,
     'Active Media' => '编修中的媒体' ,
     'Active Stories' => '编修中的稿件' ,
     'Active Templates' => '编修中的模板' ,
     'Ad String' => '广告字符串' ,
     'Ad String 2' => '广告字符串 2' ,
     'Ad Strings' => '广告字符串' ,
     'Admin' => '管理' ,
     'Advanced Search' => '进阶搜寻' ,
     'Alert Types' => '警告类型' ,
     'All' => '所有的' ,
     'All Contributors' => '所有的供稿者' ,
     'All Elements' => '所有的元素' ,
     'All Groups' => '所有的群组' ,
     'All Categories' => '所有分类' ,
     'Available Groups' => '可用的群组' ,
     'Available Output Channels' => '可用的输出频道' ,
     'Bricolage' => 'Bricolage' ,
     'By Last' => '依照姓氏' ,
     'By Source name' => '按照来源名称' ,
     'CONTACTS' => '联络人' ,
     'Caption' => '标题' ,
     'Categories' => '分类' ,
     'Category' => '分类' ,
     'Category Assets' => '分类资产' ,
     'Category Profile' => '分类档案' ,
     'Category tree' => '分类树' ,
     'Characters' => '字元' ,
     'Choose Site' => '选取站台' ,
     'Contacts' => '联络人' ,
     'Content' => '内容' ,
     'Content Type' => '内容类型' ,
     'Contributor Roles' => '供稿者角色' ,
     'Contributor Type' => '供稿者类型' ,
     'Contributor Type Profile' => '供稿者类型设定' ,
     'Contributor Types' => '供稿者类型' ,
     'Contributors' => '供稿者' ,
     'Cookie' => 'Cookie' ,
     'Copy' => '复制' ,
     'Cover Date' => '见报日期' ,
     'Current Groups' => '目前的群组' ,
     'Current Note' => '目前的注意事项' ,
     'Current Version' => '目前版本' ,
     'Currently Related Story' => '目前相关的稿件' ,
     'DISTRIBUTION' => '散布' ,
     'Data Elements' => '数据元素' ,
     'Default Value' => '预设值' ,
     'Deployed Date' => '布署的日期' ,
     'Description' => '描述' ,
     'Desk Permissions' => '桌面权限' ,
     'Desks' => '桌面' ,
     'Destinations' => '发布目标' ,
     'Directory' => '目录' ,
     'Display Name' => '显示名称' ,
     'Domain Name' => '网与名称' ,
     'Element' => '元素' ,
     'Element Profile' => '元素设定' ,
     'Element Type' => '元素类型' ,
     'Element Type Profile' => '元素类型设定' ,
     'Element Types' => '元素类型' ,
     'Elements' => '元素' ,
     'Error' => '错误' ,
     'Event Type' => '事件类型' ,
     'Events' => '事件' ,
     'Existing %n' => '%n 已经存在' ,
     'EXISTING CATEGORIES' => '已有的分类' ,
     'EXISTING DESTINATIONS' => '已有的目标' ,
     'EXISTING ELEMENT TYPES' => '已有的元素类型' ,
     'EXISTING ELEMENTS' => '已有的元素' ,
     'EXISTING MEDIA TYPES' => '已有的媒体类型' ,
     'EXISTING OUTPUT CHANNELS' => '已有的输出频道' ,
     'EXISTING SOURCES' => '已有的来源' ,
     'EXISTING USERS' => '已有的使用者' ,
     'Expiration' => '期限' ,
     'Expire Date' => '到期日' ,
     'Extension' => '扩展名' ,
     'Extensions' => '扩展名' ,
     'Fields' => '栏' ,
     'File Name' => '档案名称' ,
     'File Path' => '档案路径' ,
     'File Type' => '档案类型' ,
     'First' => '名' ,
     'First Name' => '名' ,
     'First Published' => '第一个发布的' ,
     'Fixed' => '固定的' ,
     'Generic' => '通用的' ,
     'Group Type' => '群组类型' ,
     'Groups' => '群组' ,
     'HTML::Template' => 'HTML::Template' ,
     'ID' => 'ID' ,
     'Information' => '信息' ,
     'Jobs' => '工作' ,
     'Key Name' => '识别名称' ,
     'Label' => '标记' ,
     'Last' => '姓' ,
     'Last Name' => '姓' ,
     'Legal' => 'Legal' ,
     'Log' => '纪录' ,
     'Login ' => '登入' ,
     'Login and Password' => '登入帐号与口令' ,
     'MIME Type' => 'MIME Type' ,
     'Mason' => 'Mason' ,
     'Max size' => '最大尺寸' ,
     'Maximum size' => '最大尺寸' ,
     'MEDIA' => '媒体 ' ,
     'Media' => '媒体' ,
     'Media Profile' => '媒体设定' ,
     'Media Type' => '媒体类型' ,
     'Media Type Element' => '媒体类型元素' ,
     'Media Type Profile' => '媒体类型设定' ,
     'Media Types' => '媒体类型' ,
     'Member Type  ' => '成员类型' ,
     'Members' => '成员' ,
     'My Alerts' => '我的警告' ,
     'MY WORKSPACE' => '我的工作区' ,
     'My Workspace' => '我的工作区' ,
     'NAME' => '名称' ,
     'Name' => '名称' ,
     'Never' => '永不' ,
     'New' => '新的' ,
     'New Role Name' => '新角色名称' ,
     'New password' => '新口令' ,
     'No' => '否' ,
     'No custom fields defined.' => '没有定义自定字段' ,
     'Normal' => '正常' ,
     'Note' => '注意事项' ,
     'Note saved.' => '注意事项已储存.' ,
     'Notes' => '注意事项' ,
     'OS' => '操作系统' ,
     'Old password' => '旧口令' ,
     'Option, Label' => '选项，标记' ,
     'Options, Label' => '选项、标记' ,
     'Order' => '顺序' ,
     'Organization' => '组织' ,
     'Output Channel' => '输出频道' ,
     'Output Channels' => '输出频道' ,
     'Owner' => '所有人' ,
     'PREFERENCES' => '偏好设定' ,
     'PROPERTIES' => '特性' ,
     'PUBLISHING' => '出版' ,
     'Parent Category' => '父分类' ,
     'Password' => '口令' ,
     'Pending ' => '待办' ,
     'Pending %n' => 'Pending %n' ,
     'Position' => '位置' ,
     'Post' => '字号' ,
     'Pre' => '称谓' ,
     'Preferences' => '偏好设定' ,
     'Prefix' => 'Prefix' ,
     'Previews' => '预览' ,
     'Primary Category' => '主要的分类' ,
     'Primary Output Channel' => '主要的输出频道' ,
     'Priority' => '优先权' ,
     'Profile' => '设定' ,
     'Properties' => '特性' ,
     'Publish Date' => '出版日期' ,
     'Publish Desk' => '出版桌面' ,
     'Publishes' => '出版品' ,
     'Recipients' => '收件者' ,
     'Related Media' => '相关的媒体' ,
     'Related Story' => '相关的稿件' ,
     'Repeatable' => '可重复的' ,
     'Required' => '必要的' ,
     'Resources' => '资源' ,
     'Role' => '角色' ,
     'Roles' => '角色' ,
     'STORIES' => '稿件' ,
     'SYSTEM' => '系统' ,
     'Separator String' => '分隔字符串' ,
     'Simple Search' => '简易搜寻' ,
     'Site Profile' => '站台设定' ,
     'Sites' => '站台' ,
     'Site' => '站台' ,
     'Slug' => '短标题' ,
     'Source' => '来源' ,
     'Source Profile' => '来源设定' ,
     'Source name' => '来源名称' ,
     'Sources' => '来源' ,
     'Start Desk' => '开始桌面' ,
     'Statistics' => '统计' ,
     'STORY' => '稿件' ,
     'Story' => '稿件' ,
     'Story Type' => '稿件类型' ,
     'Story Type Element' => '稿件类型' ,
     'Subelements' => '子元素' ,
     'Teaser' => 'Teaser' ,
     'TEMPLATE' => '样板' ,
     'Template Name' => '模板名称' ,
     'Template Type' => '模板类型' ,
     'Text box' => '文字方块' ,
     'Title' => '标题' ,
     'Trail' => '更改纪录' ,
     'Type' => '类型' ,
     'URI' => 'URI' ,
     'URL' => 'URL' ,
     'Username' => '使用者名称' ,
     'Users' => '使用者' ,
     'Value Name' => '值' ,
     'Version' => '版本' ,
     'Welcome to Bricolage.' => '欢迎使用 Bricolage' ,
     'Welcome to [_1].' => '欢迎使用 [_1].' ,
     'Words' => '字' ,
     'Workflow Permissions' => '流程权限' ,
     'Year' => '年' ,
     'Yes' => '是' ,
     'all' => '全部' ,
     'one per line' => '一行一个' ,
     'to' => '到' ,

     # Action Commands
     'Associate' => '关联' ,
     'Add New Field' => '新增一个字段' ,
     'Add a New Alert Type' => '新增警告类型' ,
     'Add a New Category' => '新增分类' ,
     'Add a New Contributor' => '新增供稿者' ,
     'Add a New Contributor Type' => '新增供稿者类型' ,
     'Add a New Desk' => '新增桌面' ,
     'Add a New Destination' => '新增目标' ,
     'Add a New Element Type' => '新增元素类型' ,
     'Add a New Element' => '新增元素' ,
     'Add a New Group' => '新增群组' ,
     'Add a New Media Type' => '新增媒体类型' ,
     'Add a New Output Channel' => '新增输出频道' ,
     'Add a New Source' => '新增来源' ,
     'Add a New Workflow' => '新增流程' ,
     'Add a New Keyword' => '新增关键词' ,
     'Add a New User' => '新增使用者' ,
     'Add to Element' => '加入到元素' ,
     'Add to Include' => '将这些包含在内' ,
     'Add' => '新增' ,
     'Allow multiple' => '允许多选' ,
     'Burner' => 'Burner' ,
     'Check In Assets' => '送回资产' ,
     'Check In to Edit' => '送回给编辑' ,
     'Check In to Publish' => '送回至 Publish' ,
     'Check In to' => '送回到' ,
     'Check In' => '送回' ,
     'Checkin' => '送回' ,
     'Check Out' => '取出' ,
     'Checkout' => '取出' ,
     'Choose Contributors' => '选取供稿者' ,
     'Choose Related Media' => '选择相关的媒体' ,
     'Choose Subelements' => '选择子元素' ,
     'Create a New Category' => '建立新的分类' ,
     'Create a New Media' => '建立一个新的媒体' ,
     'Create a New Story' => '建立一份新的稿件' ,
     'Create a New Template' => '建立新模板' ,
     'Delete this Desk from all Workflows' => '自所有流程中删除此桌面' ,
     'Delete this Element' => '删除这个元素' ,
     'Delete this Profile' => '删除这个设定' ,
     'Delete' => '删除' ,
     'Deploy' => '布署' ,
     'Download' => '下载' ,
     'Edit' => '编辑' ,
     'Expire' => '到期' ,
     'Find Media' => '搜寻媒体' ,
     'Find Stories' => '搜寻稿件' ,
     'Find Templates' => '搜寻模板' ,
     'Manage' => '管理' ,
     'Move Assets' => '移动资产' ,
     'Move to' => '移到' ,
     'New Media ' => '新的媒体 ' ,
     'New Media' => '新的媒体' ,
     'New Story' => '新的稿件' ,
     'New Template' => '新的样板' ,
     'Preview in' => '预览' ,
     'Publish' => '出版' ,
     'Relate' => '加入关系' ,
     'Remove' => '移除' ,
     'Repeat new password' => '新口令确认' ,
     'SEARCH' => '寻找' ,
     'SUBMIT' => '送出' ,
     'Scheduler' => '排程' ,
     'Select Desk' => '选一个桌面' ,
     'Select Role' => '选择角色' ,
     'Select an Event Type' => '选择一个事件类型' ,
     'Select' => '选择' ,
     'Sort By' => '排序方式' ,
     'Submit' => 'Submit' ,
     'Switch Roles' => '变换角色' ,
     'Template Profile' => '模板设定' ,
     'Template Code' => '模板 Code' ,
     'Un-Associate' => '解除关联' ,
     'Upload a file' => '上传档案' ,
     'User Override' => '使用其它身分登入' ,
     'View' => '查看' ,
     'Workflow Profile' => 'Workflow Profile' ,
     'Grant "[_1]" members permission to access assets in these categories.' => '允许 [_1] 成员权限得以存取这些分类里面的资产。' ,
     'Grant "[_1]" members permission to access assets in these workflows.' => '允许 [_1] 成员权限能够存取这些流程里面的资产。' ,
     'Grant "[_1]" members permission to access assets on these desks.' => '允许 [_1] 成员权限得以存取这些桌面的资产。' ,
     'Grant "[_1]" members permission to access the members of these groups.' => '允许 [_1] 成员之权限得以存取这些群组里面之成员' ,
     'Grant the members of the following groups permission to access the members of the "[_1]" group.' => '允许以下群组的成员得以存取 [_1] 群组的成员。' ,
     '' => '' ,

     # System reply messages
     '"[_1]" Elements saved.' => '[_1] 元素已被储存。' ,
     '%n Found' => '找到的%n' ,
     '404 NOT FOUND' => '404 网页找不到' ,
     'A site with the [_1] "[_2]" already exists' => '[_1]「[_2]」 已经存在于某个站台中了' ,
     'Action profile "[_1]" deleted.' => '行动设定「[_1]」已删除' ,
     'Action profile "[_1]" saved.' => '行动设定「[_1]」已储存' ,
     'Add a New Action' => '新增行动设定' ,
     'Add a New Server' => '新增服务器' ,
     'Alert Type profile "[_1]" deleted.' => '警告类型设定「[_1]」已删除' ,
     'Alert Type profile "[_1]" saved.' => '警告类型设定「[_1]」已储存' ,
     'Alias in Category' => '分类中别名' ,
     'Alias to "[_1]" created and saved.' => '已经建立并储存 "[_1]" 的别名' ,
     'All Types' => '所有类型' ,
     'An "[_1]" attribute already exists. Please try another name.' => ' 「[_1]」 属性已经存在，请选择别的名称' ,
     'An active template already exists for the selected output channel, category, element and burner you selected.  You must delete the existing template before you can add a new one.' => 'An active template already exists for the selected 所选的输出频道、分类、元素中已存在一个行动模板，你必须在储存前删除现有的模板' ,
     'An error occurred while processing your request:' => '在处理您的要求时，发生了一个错误；' ,
     'An error occurred.' => '发生错误。' ,
     'At least one extension is required.' => '至少需要一个扩展名' ,
     'Bad element name "[_1]". Did you mean "[_2]"?' => '元素名称错误：「[_1]」。也许您是指「[_2]」？' ,
     'Cannot auto-publish related media "[_1]" because it is checked out.' => '无法自动出版相关的媒体 [_1] ，因为它尚未被送回' ,
     'Cannot auto-publish related story "[_1]" because it is checked out.' => '因其仍被他人取出修改中，所以无法自动出版以下此篇相关的稿件：「[_1]」' ,
     'Cannot both delete and make primary a single output channel.' => '不能够同时设定其为主要输出频道，却又将它删除' ,
     'Cannot cancel "[_1]" because it is currently executing.' => '不能取消 [_1] ，因为它目前正在执行中。' ,
     'Cannot create an alias to a media in the same site.' => '在同站之中无法建立媒体的别名' ,
     'Cannot create an alias to a story in the same site.' => '在同站之中无法建立稿件的别名' ,
     'Cannot move "[_1]" asset "[_2]" while it is checked out' => '因为被取出了，所以不能移动 "[_1]" 资产: "[_2]"' ,
     'Cannot preview asset "[_1]" because there are no Preview Destinations associated with its output channels.' => '无法预览此资产：「[_1]」。其输出频道没有对应到任何预览用的发布目标。' ,
     'Cannot publish asset "[_1]" to "[_2]" because there are no Destinations associated with this output channel.' => '无法将资产「[_1]]」发布到「[_2]]」，因为此输出频道没有设定散布目标。' ,
     'Cannot publish checked-out media "[_1]"' => '尚未送回的媒体 [_1] 不能被出版' ,
     'Cannot publish checked-out story "[_1]"' => '未送回的稿子 [_1] 不能出版' ,
     'Cannot publish media "[_1]" because it is checked out.' => '因为被取出了，所以无法出版以下媒体：「[_1]」' ,
     'Cannot publish story "[_1]" because it is checked out.' => '因为被取出了，所以无法出版以下稿件：「[_1]」' ,
     'Cascade into Subcategories' => 'Cascade into Subcategories' ,
     'Category "[_1]" added.' => '加入 [_1] 分类。' ,
     'Category "[_1]" cannot be deleted.' => '不能删除 [_1] 这个分类。' ,
     'Category "[_1]" disassociated.' => '已经「[_1]」这个分类断绝关系。' ,
     'Category Permissions' => '分类权限' ,
     'Category URI' => '分类URI' ,
     'Category profile "[_1]" and all its categories deleted.' => '分类设定 [1] 与其所有分类皆已删除。' ,
     'Category profile "[_1]" deleted.' => '分类设定 [_1] 已删除。' ,
     'Category profile "[_1]" saved.' => '分类设定 [_1] 已储存。' ,
     'Changes not saved: permission denied.' => '无法储存：权限遭拒' ,
     'Check In to [_1]' => '送回到 [_1]' ,
     'Choose a Related Story' => '选择相关的稿件' ,
     'Contributor "[_1]" disassociated.' => '已断绝供稿者 [_1] 的关系。' ,
     'Contributor Type Manager' => '供稿者类型管理' ,
     'Contributor profile "[_1]" deleted.' => '供稿者设定 [_1] 已删除。' ,
     'Contributor profile "[_1]" saved.' => '供稿者设定 [_1] 已储存。' ,
     'Contributors disassociated.' => '已断绝供稿者的关系' ,
     'Copy Resources' => '复制一份' ,
     'Cover Date incomplete.' => '见报日期不完整。' ,
     'Delete this Category and All its Subcategories' => '删除这个分类以及其所有子分类' ,
     'Deployed Version' => '部署版本' ,
     'Desk profile "[_1]" deleted from all workflows.' => '[_1] 桌面设定已自所有的流程中删除。' ,
     'Destination' => '目标' ,
     'Destination Profile' => '目标设定' ,
     'Destination not specified' => '尚未指定发布目标' ,
     'Destination profile "[_1]" deleted.' => '发布目标 [_1] 已删除。' ,
     'Destination profile "[_1]" saved.' => '发布目标 [_1] 已储存。' ,
     'Directory name "[_1]" contains invalid characters. Please try a different directory name.' => '目录名称[_1]还有非法的字元，请调整目录名称。' ,
     'Distributing files.' => '档案散布中' ,
     'Document Root' => '文件根目录' ,
     'Element "[_1]" deleted.' => '[_1]元素已删除。' ,
     'Element "[_1]" saved.' => '[_1]元素已储存' ,
     'Element Type profile "[_1]" deleted.' => '[_1] 元素类型设定已删除。' ,
     'Element Type profile "[_1]" saved.' => '[_1] 元素类型设定已储存。' ,
     'Expire Date incomplete.' => '到期日不完整。' ,
     'Extension "[_1]" ignored.' => '已忽略 [_1] 扩展名' ,
     'Extension "[_1]" is already used by media type "[_2]".' => '[_1] 扩展名已被其它媒体类型所用' ,
     'FTP' => 'FTP' ,
     'Field "[_1]" appears more than once but it is not a repeatable element.  Please remove all but one.' => '「[_1]」字段出现了一次以上，不过它并非可重复的元素，因此请移除多馀的部份。' ,
     'Field profile "[_1]" deleted.' => '已删除无效的设定：「[_1]」' ,
     'Field profile "[_2]" saved.' => '无效的设定已储存：「[_2]」' ,
     'File System' => '档案系统' ,
     'Find Media To Alias' => '找出要取别名的媒体' ,
     'Find Story To Alias' => '找出要取别名的稿件' ,
     'Find a media to alias' => '找出要取别名的媒体' ,
     'Find a story to alias' => '找出要取别名的稿件' ,
     'From' => '来自' ,
     'Group Label' => '群组标记' ,
     'Group Memberships' => '群组成员' ,
     'Group cannot be deleted.' => '群组无法删除' ,
     'Group profile "[_1]" deleted.' => '群组设定 [_1] 已删除。' ,
     'Group profile "[_1]" saved.' => '群组设定 [_1] 已储存' ,
     'Hi [_1]!' => '[_1] 早安!' ,
     'Host Name' => '主机名称' ,
     'Invalid date value for "[_1]" field.' => '日期字段「[_1]」的值无效' ,
     'Invalid page request' => '无效的页面要求' ,
     'Invalid password. Please try again.' => '口令无校，请再试一次' ,
     'Invalid username or password. Please try again.' => '使用者名称或者口令无效，请再试一次。' ,
     'Job profile "[_1]" deleted.' => '工作设定 [_1] 已删除。' ,
     'Job profile "[_1]" saved.' => '工作设定 [_1] 已储存。' ,
     'Keyword' => '关键词' ,
     'Keyword Manager' => '关键词管理' ,
     'Keyword Profile' => '关键词设定' ,
     'Keywords' => '关键词' ,
     'Keywords saved.' => '关键词已储存。' ,
     'Login "[_1]" contains invalid characters.' => '登入帐号 [_1] 内含非法字元啊！' ,
     'Login "[_1]" is already in use. Please try again.' => '登入 [_1] 已被使用，请再试一次。' ,
     'Login cannot be blank. Please enter a login.' => '登入字段不能留白，请务必正确输入' ,
     'Login must be at least [_1] characters.' => '登入帐号至少要有 [_1] 个字元' ,
     'MEDIA FOUND' => '找到的媒体' ,
     'Media "[_1]" check out canceled.' => '已取消取出媒体 [_1] 。' ,
     'Media "[_1]" created and saved.' => '媒体 [_1] 已建立，并且储存。' ,
     'Media "[_1]" deleted.' => '媒体 [_1] 已删除。' ,
     'Media "[_1]" published.' => 'Media [_1] 已正式公开出版。' ,
     'Media "[_1]" reverted to V.[_2]' => '媒体 [_1] 已回复到第 [_2] 版' ,
     'Media "[_1]" saved and checked in to "[_2]".' => '媒体 [_1] 已储存，并送回到 [_2].' ,
     'Media "[_1]" saved and moved to "[_2]".' => '媒体 [_1] 已储存，且移动至 [_2]。' ,
     'Media "[_1]" saved and shelved.' => '媒体 [_1] 已储存，但暂时搁置。' ,
     'Media "[_1]" saved.' => '媒体 [_1] 已储存。' ,
     'Media Type profile "[_1]" deleted.' => '媒体类型设定 [_1] 已经储存。' ,
     'Media Type profile "[_1]" saved.' => '媒体类型 [_1] 已储存。' ,
     'Move Method' => '移动方法' ,
     'Move to Desk' => '移到桌面' ,
     'Name is required.' => '名称为必要的。' ,
     'Needs to be Deployed' => '必须开始部署' ,
     'Needs to be Published' => '必须开始出版' ,
     'New Alias' => '新别名' ,
     'New passwords do not match. Please try again.' => '新口令不符，请再输入一次' ,
     'No Alias' => '没有别名' ,
     'No alert types were found' => '找不到警告类型' ,
     'No categories were found' => '找不到分类' ,
     'No contributor types were found' => '找不到供稿者类型' ,
     'No contributors defined' => '未有定义好的供稿者' ,
     'No contributors defined.' => '未定义任何供稿者' ,
     'No destinations were found' => '找不到目标' ,
     'No element types were found' => '找不到元素类型设定' ,
     'No elements are present.' => '找不到元素' ,
     'No elements have been added.' => '没有加入任何元素。' ,
     'No elements were found' => '找不到元素' ,
     'No existing notes.' => '并无注意事项' ,
     'No file associated with media "[_1]". Skipping.' => '「[_1]」媒体并无相关的档案，在此略过。' ,
     'No file has been uploaded' => '没有任何已上传的档案。' ,
     'No groups were found' => '找不到群组' ,
     'No jobs were found' => '找不到工作' ,
     'No keywords defined.' => '未定义任何关键词' ,
     'No media file is associated with asset "[_1]", so none will be distributed.' => '由于 [_1] 资产完全没有相关的媒体档案，所以并不会将档案散布出去。' ,
     'No media types were found' => '找不到媒体类型' ,
     'No media were found' => '找不到媒体' ,
     'No output channels were found' => '并没有找到任何输出频道' ,
     'No output to preview.' => '无预览输出' ,
     'No related Stories' => '无相关的稿件' ,
     'No servers were found' => '找不到服务器' ,
     'No sources were found' => '找不到来源' ,
     'No stories were found' => '找不到任何稿件' ,
     'No templates were found' => '找不到样板' ,
     'No users were found' => '找不到使用者' ,
     'No workflows were found' => '找不到流程' ,
     'Note: Container element "[_1]" removed in bulk edit but will not be deleted.' => '注意：容器元素「[_1]」在大量编辑模式中被去掉了，但它并不会被删除。' ,
     'Note: Data element "[_1]" is required and cannot be completely removed.  Will delete all but one.' => '注意：数据元素「[_1]」为必要的，因此不能全部被移除，将会留下其中一个。' ,
     'Object Groups' => '对象群组' ,
     'Object Group Permissions' => '对象群组权限' ,
     'Or Pick a Type' => '或选择一个类型' ,
     'Output Channel profile "[_1]" deleted.' => '输出频道设定 [_1] 已删除。' ,
     'Output Channel profile "[_1]" saved.' => '输出频道 [_1] 已被储存。' ,
     'PENDING JOBS' => '待办工作' ,
     'Parent cannot choose itself or its child as its parent. Try a different parent.' => '一个节点不能把自己或其子节点设定为自己的母节点，请选择别的节点。' ,
     'Password contains illegal preceding or trailing spaces. Please try again.' => '口令前后有非法的空白字元，请再试一次。' ,
     'Passwords cannot have spaces at the beginning!' => '口令开头不能是空白字元啊！' ,
     'Passwords cannot have spaces at the end!' => '口令最后不能有空白字元啊！' ,
     'Passwords do not match!  Please re-enter.' => '口令不一致，请重新输入' ,
     'Passwords must be at least [_1] characters!' => '口令至少要有 [_1] 个字元！' ,
     'Passwords must match!' => '口令必须要一致' ,
     'Permission Denied' => '权限惨遭拒绝' ,
     'Permission to checkout "[_1]" denied.' => '取出 [_1] 的权限遭到拒绝' ,
     'Permission to delete "[_1]" denied.' => '删除 [_1] 权限遭到拒绝' ,
     'Permissions saved.' => '权限已储存' ,
     'Please check the URL and try again. If you feel you have reached this page as a result of a server error or other bug, please notify the server administrator. Be sure to include as much detail as possible, including the type of browser, operating system, and the steps leading up to your arrival here.' => '请仔细检查URL并且再试一次。如果你觉得你是因为某种服务器产生的错误而来到这个页面，请尽速通知管理员，并请附上尽量详细的信息，包括使用的浏览器、操作系统、以及达到这一页的每个步骤。' ,
     'Please click [_1]here[_2] to start.' => '请点选 [_1]这里[_2] 开始' ,
     'Please log in:' => '请登入：' ,
     'Please select a primary category.' => '请选择一个主要的分类' ,
     'Please select a primary output channel.' => '请选择一个主要的输出频道' ,
     'Please select a story type.' => '请选择一个稿件类型' ,
     'Preference "[_1]" updated.' => '偏好设定 [_1] 已更新。' ,
     'Problem adding "[_1]"' => '增加 [_1] 时发生问题' ,
     'Problem deleting "[_1]"' => '删除 [_1] 时发生问题。' ,
     'Published Version' => '出版的版本' ,
     'Redirecting to preview.' => '重导到预览' ,
     'Related Media to Alias' => '替相关媒体取别名' ,
     'Related Story to Alias' => '替相关稿件取别名' ,
     'STORY INFORMATION' => '稿件信息' ,
     'Scheduled Time' => '排定的时间' ,
     'Select Alias' => '选取别名' ,
     'Select Categories' => '选取分类' ,
     'Separator Changed.' => '分隔字元已更动。' ,
     'Server profile "[_1]" deleted.' => '服务器设定 [_1] 已经储存。' ,
     'Server profile "[_1]" saved.' => '服务器设定 [_1] 已储存。' ,
     'Servers' => '服务器' ,
     '[_1] Site [_2] Permissions' => '[_1] 站台 [_2] 许可' ,
     '[_1] Site Categories' => '[_1] 站台分类' ,
     'Site "[_1]" requires a primary output channel.' => '需要主要的输出频道：站台 「[_1]」 ' ,
     'Site profile "[_1]" deleted.' => '站台设定「[_1]」已删除' ,
     'Site profile "[_1]" saved.' => '站台设定「[_1]」已储存' ,
     'Slug must conform to URI character rules.' => 'Slug 也必须依循 URI 字元的规则' ,
     'Sort Name' => '排序名称' ,
     'Source profile "[_1]" deleted.' => '来源设定 [_1] 已删除。' ,
     'Source profile "[_1]" saved.' => '来源设定 [_1] 已储存。' ,
     'Status' => '状态' ,
     'Stories' => '稿件' ,
     'Stories in this category' => '这个分类里面的稿件' ,
     'Story "[_1]" check out canceled.' => '取消取出稿件 [_1]。' ,
     'Story "[_1]" created and saved.' => '稿件 [_1] 已建立，并且储存。' ,
     'Story "[_1]" deleted.' => '稿件 [_1] 已删除。' ,
     'Story "[_1]" published.' => '稿件 [_1] 已出版。' ,
     'Story "[_1]" reverted to V.[_2].' => '稿件 [_1] 已回复到第 [_2] 版。' ,
     'Story "[_1]" saved and checked in to "[_2]".' => '稿件 [_1] 已储存，送回至 [_1] 。' ,
     'Story "[_1]" saved and moved to "[_2]".' => '稿件 [_1] 已储存，移动至 [_2] 。' ,
     'Story "[_1]" saved and shelved.' => '稿件 [_1] 已储存，但暂时搁置。' ,
     'Story "[_1]" saved.' => '稿件 [_1] 已储存。' ,
     'Template "[_1]" check out canceled.' => '取消取出样板 [_1]。' ,
     'Template "[_1]" deleted.' => '模板 [_1] 已删除。' ,
     'Template "[_1]" saved and checked in to "[_2]".' => 'Template "[_1]" saved and checked in to "[_2]".' ,
     'Template "[_1]" saved and moved to "[_2]".' => '模板 [_1] 已建立，并且移动至 [_2]' ,
     'Template "[_1]" saved and shelved.' => '模板 [_1] 已建立，但暂时搁置。' ,
     'Template "[_1]" saved.' => '模板 [_1] 已储存。' ,
     'Template Includes' => '模板包括了...' ,
     'Template compile failed: [_1]' => '模板编译失败: [_1]' ,
     'Template deployed.' => '模板已经配备完成' ,
     'Templates' => '模板' ,
     'Templates Found' => '找到的模板' ,
     'Text to search' => '要找的文字' ,
     'The URI "[_1]" is not unique. Please change the cover date, output channels, category, or file name as necessary to make the URIs unique.' => '这个 URI "[_1]" 不是独一无二的。 请更换封面日期、输出频道、分类、或是档案名称使其独一无二' ,
     'The URL you requested, <b>[_1]</b>, was not found on this server' => '在这台服务器上，并没有找到所求之 URL <b>[_1]</b> ' ,
     'The name "[_1]" is already used by another Alert Type.' => '「[_1]」这个名称已经被其它的警告类型使用' ,
     'The name "[_1]" is already used by another Desk.' => '「[_1]」这个名称已经被其它的桌面使用' ,
     'The name "[_1]" is already used by another Destination.' => '「[_1]」这个名称已经被其它的发布目标使用' ,
     'The name "[_1]" is already used by another Element Type.' => '[_1] 这名称已经被其它的元素类型使用。' ,
     'The name "[_1]" is already used by another Media Type.' => '[_1] 这个名称已被其它的媒体类型使用。' ,
     'The name "[_1]" is already used by another Output Channel.' => '[_1] 这个名字已经被其它的输出频道使用' ,
     'The name "[_1]" is already used by another Server in this Destination.' => ' 目的地「[_1]」这个名称已经在别的服务器被使用' ,
     'The name "[_1]" is already used by another Source.' => '[_1] 这个名称已经被其它的来源采用' ,
     'The name "[_1]" is already used by another Workflow.' => '其它流程已经使用了 [_1] 这个名字' ,
     'The slug can only contain alphanumeric characters (A-Z, 0-9, - or _)!' => 'Slug 里面只能用英文字母、阿拉伯数字、短线、与底线字元！' ,
     'The slug, category and cover date you selected would have caused this story to have a URI conflicting with that of story [_1].' => '这篇稿件所选的的 slug、分类、以及见报日期，将使其 URI 与「[_1]」这篇稿件相同' ,
     'This day does not exist! Your day is changed to the' => '这一天根本不存在啊！它已经被改为' ,
     'This story has not been assigned to a category.' => '这份稿件目前尚未被分类' ,
     'To' => 'To' ,
     'URI "[_1]" is already in use. Please try a different directory name or parent category.' => 'URI [_1] 已被使用，请调整目录名称或者是分类。' ,
     'Un-relate' => '解除关系' ,
     'User profile "[_1]" deleted.' => '使用者设定 [_1] 已删除。' ,
     'User profile "[_1]" saved.' => '使用者设定「[_1]」已储存' ,
     'Usernames must be at least 6 characters!' => '使用者名称至少需要六个字元' ,
     'Using Bricolage without JavaScript can result in corrupt data and system instability. Please activate JavaScript in your browser before continuing.' => '使用 Bricolage 时无 JavaScript 功能可能造成数据损毁及系统不稳，进行下一部以前请打开浏览器中 JavaScript 功能' ,
     'V.' => 'V.' ,
     'Value of [_1] cannot be empty' => '[_1] 的值不能是空白' ,
     'Warning! Bricolage is designed to run with JavaScript enabled.' => '警告！ Bricolage 设计成必须使用 JavaScript' ,
     'Warning! State inconsistent: Please use the buttons provided by the application rather than the \'Back\'/\'Forward\' buttons.' => 'Warning! State inconsistent: Please use the buttons provided by the application rather than the \'Back\'/\'Forward\' buttons.' ,
     'Warning:  Use of element\'s \'name\' field is deprecated for use with element method \'get_container\'.  Please use the element\'s \'key_name\' field instead.' => '警告: 以 \'name\' 字段呼叫 \'get_container\' 的使用方式已被废弃不用。请改用元素的 \'key_name\' 字段。',
     'Warning:  Use of element\'s \'name\' field is deprecated for use with element method \'get_data\'.  Please use the element\'s \'key_name\' field instead.' => '警告: 以 \'name\' 字段呼叫 \'get_data\' 的使用方式已被废弃不用。请改用元素的 \'key_name\' 字段。',
     'Warning: object "[_1]" had no associated desk.  It has been assigned to the "[_2]" desk.' => '警告：[_1] 没有所属的桌面，它已经被移动到 [_2] 这个桌面。' ,
     'Warning: object "[_1]" had no associated workflow.  It has been assigned to the "[_2]" workflow.' => '警告：「[_1]」对象并不属于任何流程，所以已经被放入「[_2]」流程中。' ,
     'Warning: object "[_1]" had no associated workflow.  It has been assigned to the "[_2]" workflow. This change also required that this object be moved to the "[_3]" desk.' => '警告：「[_1]」对象并不属于任何流程，所以已经被放入「[_2]」流程中。此项异动同时已把对象移到「[_3]」桌面。' ,
     'Welcome to [_1]' => '欢迎来到 [_1]' ,
     'Workflow profile "[_1]" deleted.' => '流程 profile 「[_1]」 已删除.' ,
     'Writing files to "[_1]" Output Channel.' => '正将档案写至「[_1]」输出频道' ,
     'You are about to permanently delete items! Do you wish to continue?' => '这些项目将被永久删除！真的要继续吗？' ,
     'You cannot remove all Sites.' => '您不能移除所有站台' ,
     'You have not been granted <b>[_1]</b> access to the <b>[_2]</b> [_3]' => '您并未允许 <b>[_1]</b> 存取 <b>[_2]</b> [_3]' ,
     'You must be an administrator to use this function.' => '此功能只有管理员才可使用' ,
     'You must select an Element or check the &quot;Generic&quot; check box.' => '你必须选择一个元素，或是核选「通用」的核选方块' ,
     'You must select an Element.' => '您必须选择一个元素' ,
     'You must supply a unique name for this role!' => '你必须替这个角色取个独一无二的名字' ,
     'You must supply a value for ' => '您必须给定其值' ,
     '[_1] recipients changed.' => '[_1] 个收件者已更动。' ,
     '[quant,$quant,Contributors] [_1] [quant,$quant,disassociated].' => '[quant,$quant,个供稿者] [_1] [quant,$quant,解除关系].' ,
     '[quant,_1,Alert] acknowledged.' => '警告已被确认' ,
     '[quant,_1,Contributor] "[_2]" associated.' => '已关联至此供稿者：「[_2]」' ,
     '[quant,_1,Template] deployed.' => '模板已经配备完成' ,
     '[quant,_1,media,media] published.' => '[_1] 个媒体出版完成。' ,
     '[quant,_1,story,stories] published.' => '[_1] 篇稿件出版完成。' ,
     'contains illegal characters!' => '含有不合法的字元！' ,
     '_AUTO' => '1' ,
    );

=begin comment

To translate:
  '[_1] Site [_2] Permissions' => '[_1] [_2] Permissions', # Site Category Permissions
  'All Categories' => '所有分类',
  'Object Groups' => '对象群组',
  '[_1] Site Categories' => '[_1] 站台分类',
  'You do not have permission to override user "[_1]"' => '您不得 override 使用者 "[_1]"'
  'Please select a primary output channel' => '请选择一个主要输出频道',

Notice:

  Story 请一律译成「稿件」「稿子」或著「稿」，不要译成「故事」

=end comment

=cut

1;

__END__

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>, Jimmy <jimmybric@tp4.us>.

=head1 SEE ALSO

L<Bric::Util::Language|Bric::Util::Language>

=cut


1;
