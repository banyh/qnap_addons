# Download Station Addon Developer's Guide v4

## Addon 目錄結構

1. 前往 Addon 所在目錄

```shell
export DEFAULT_VOLUME=`/sbin/getcfg -f /etc/config/def_share.info SHARE_DEF defVolMP`
cd ${DEFAULT_VOLUME}/.qpkg/DSv3/usr/sbin/addons
```

2. 裡面每個子目錄，都包含三個檔案
    * `addon.json`: 包含 Addon 的名稱、描述、版本號等資訊。Download Station 會讀取這個檔案，了解這個 Addon 的功能。
    * `addon.key`: 這是標準的 RSA public key file，用來驗證 Addon 是否被改過。在 release Addon 時，會執行`ds-addon-pack.sh`自動壓縮所有檔案並產生 RSA private key。
    * `*.php`: 這是 Addon 執行的主程式，Download Station 有提供五個 interface `ISite, IRss, IVerity, ISearch, IDownload` 讓你決定程式的功能。這個程式至少要實作`ISite`及預設的 constructor，其他功能則是可選的。

## `ds-addon-pack.sh` 及 Release 流程

1. 先移動到`${DEFAULT_VOLUME}/.qpkg/DSv3/usr/sbin`目錄

2. 首先需要產生1024位元的 RSA Private Key
    `/usr/bin/openssl genrsa -out private.pem 1024`

3. 產生對應的 RSA Public Key
    `/usr/bin/openssl rsa -in private.pem -out public.pem -outform PEM -pubout`

4. 壓縮製作好的 Addon
    `./ds-addon-pack.sh private.pem public.pem addons/torrentreactor.net/`

5. 最後會得到`torrentreactor.net.addon`，可以在 Download Station 中加入。

## `ds-addon` 及安裝流程

1. 先移動到`${DEFAULT_VOLUME}/.qpkg/DSv3/usr/sbin`目錄

2. `./ds-addon -a` 可以列出安裝的 Addons

3. `./ds-addon -i <addon file>` 可以安裝 Addon File

4. `./ds-addon -e <addon>` 可以啟用某個 Addon，名稱必須與列出的一致

5. `./ds-addon -c <domain name> <class name>` 可以在 `addon/` 目錄下建立初始的 `addon.json` 及 `<domain name>.php`

## `ds-addon` 及測試流程

1. 先移動到`${DEFAULT_VOLUME}/.qpkg/DSv3/usr/sbin`目錄

2. `./ds-addon -a` 可以列出安裝的 Addons

3. `./ds-addon --rss <addon> <url>`
    用來測試`IRss` Addon，`<url>`會作為參數傳進去。

4. `./ds-addon --search <addon> <keyword> [limit] [category]`
    用來測試`ISearch` Addon，`<keyword>, [limit], [category]`是參數。

5. `./ds-addon --download <addon> <url>`
    用來測試`IDownload` Addon，`<url>`是參數。

6. `./ds-addon --verity <addon>`
    用來測試`IVerify` Addon，不用參數。

註：以上四個測試指令`--rss, --search, --download, --verify`最後面都可以加上`[username] [password]`兩項參數。

## 錯誤代碼

|Dec | Hex    | 說明
|----|--------|------------------------------------
| 0  | 0x0000 | 一切正常
| 1  | 0x0001 | 工具參數錯誤
| 2  | 0x0002 | 此Addon被其他程式執行中
| 3  | 0x0003 | 找不到Addon
| 4  | 0x0004 | Addon已存在
| 5  | 0x0005 | Addon不合法
| 6  | 0x0006 | Addon簽名或版本不符
| 7  | 0x0007 | Addon安裝失敗
| 8  | 0x0008 | Addon class name 名稱與規格不符
| 9  | 0x0009 | Addon 規格文法錯誤
| 10 | 0x000A | Addon runtime exception
| 11 | 0x000B | Addon未啟用
| 12 | 0x000C | URL格式錯誤
| 13 | 0x000D | 規格中的介面未實作
| 14 | 0x000E | Addon無法理解此URL
| 15 | 0x000F | Addon認證失敗
| 16 | 0x0010 | Addon只允許premium user account
| 17 | 0x0011 | 下載連結格式錯誤
| 18 | 0x0012 | 搜尋連結格式錯誤
| 19 | 0x0013 | RSS連結格式錯誤
| 20 | 0x0014 | 找不到Addon所需的app或函式庫

# Addon Definition: `addon.json`

```json
{
    "author": "dokkis",
    "website": "https://github.com/dokkis/qnap-torrent-providers",
    "name": "thepiratebay.org",
    "addon": "thepiratebay.org.php",
    "class": "thepiratebay",
    "hosts": [
        "thepiratebay.org"
    ],
    "domain": "thepiratebay.org",
    "version": 100,
    "interface": [
        "ISearch"
    ],
    "qpkg_dependencies": {
        "DownloadStation": "5.0.1"
    },
    "description": {
        "ENG": "ThePirateBay.org torrent search provider."
    }
}
```

* author: 作者名稱，可以為空字串
* website: Addon 的網址，可以為空字串
* name: Addon 的顯示名稱
* addon: Addon 執行檔的檔名 (副檔名必定為php)
* class: 在 Addon 執行檔中，實作 `ISite` interface 的 class
* hosts: Download Station 會用 hosts 決定URL的內容
* domain: Addon 的資料夾名稱
* version: 版本號，最小值為100，這個值除以100就是顯示的版本，例如230會顯示為`2.30`
* interface: 在`IRss, IVerity, ISearch, IDownload`四個可選功能中，有實作那幾項功能
* qpkg_dependencies: 預設值為`{"DownloadStation": "5.0.0"}`
* description: Addon 的描述，格式為`"語言代碼": "該語言的描述"`，至少要有英文。下列為語言代碼
    * `ENG`: English
    * `SCH`: 简体中文
    * `TCH`: 繁體中文
    * `CZE`: Czech
    * `DAN`: Dansk
    * `GER`: Deutsch
    * `SPA`: Español
    * `FRE`: Français
    * `ITA`: Italiano
    * `JPN`: 日本語
    * `KOR`: 한 글
    * `NOR`: Norsk
    * `POL`: Polski
    * `RUS`: Русский
    * `FIN`: Suomi
    * `SWE`: Svenska
    * `DUT`: Nederlands
    * `TUR`: Turk dili
    * `THA`: ไทย
    * `HUN`: Magyar
    * `POR`: Português
    * `GRK`: Ελληνικά
    * `ROM`: Român

# Addon Implementation

## `ISite`

這是最重要也是必須要實作的 interface。當 Download Station 啟動一個 Addon 時，會呼叫 constructor 並傳入 url, username, password, meta 四個參數。開發者可以決定如何使用這四個參數，也可以不用。

Download Station 5.0 開始的版本，會傳第四個參數`$meta`，但只用來作 QNAP 內部測試，一般開發者用不到。

```php
interface ISite {
    /*
     * @param {string} $url
     * @param {string} $username
     * @param {string} $password
     * @param {string} $meta
     */
    public function __construct($url = null, $username = null, $password = null, $meta = null);
}
```

實作範例如下
```php
<?php
class XXX implements ISite {
    private $url;
    public function __construct($url = null, $username = null, $password = null, $meta = null) {
        $this->url = $url;
    }
?>
```

## `IRss`

如果網站本身有 RSS feed，Download Station 可以自動處理。但如果沒有提供 RSS feed，`IRss` interface 可用來爬下網站，傳回 `RssFeed` array。

```php
interface IRss {
    /*
     * ReadRss()
     * @return {array} RssFeed array
     */
    public function ReadRss();
}
```

`RssFeed`已在php環境中定義如下，直接用`$feed = new RssFeed;`即可。
```php
final class RssFeed {
    public $link = "";      // URL
    public $title = "";     // 標題或檔名
}
```

## `ISearch`

`ISearch` 可以輸入關鍵字，然後傳回 `SearchLink` array，代表搜尋到的資源清單。

```php
interface ISearch {
    /*
     * Search()
     * @param {string} $keyword
     * @param {integer} $limit
     * @param {string} $category
     * @return {array} SearchLink array
    */
    public function Search($keyword, $limit, $category);
}
```

`SearchLink`已在php環境中定義如下，直接用`$link = new SearchLink;`即可。
```php
final class SearchLink {
    public $src = "";             // 搜尋引擎名稱、或資源提供者名稱
    public $link = "";            // URL
    public $name = "";            // 標題、檔名或簡短的描述
    public $size = 0;             // 檔案大小
    public $time;                 // 資源建立時間，必須是 NULL 或 PHP DateTime
    public $seeds = 0;            // seeds 的數量
    public $peers = 0;            // peers 的數量
    public $category = "";        // 這項資源的類別
    public $enclosure_url = "";   // magnet link 或下載的URL
}
```

## `IVerify`

`IVerify` 唯一的用途是檢查帳號密碼是否合法。帳號、密碼在一開始初始化`ISite`時就給了。

```php
interface IVerify {
    /*
     * Verify()
     * @return {boolean}
     */
    public function Verify();
}
```

## `IDownload`

當要下載的URL藏在 JavaScript、routing table、cookie 裡面時，`IDownload` 的 `GetDownloadLink()` 可以協助 Download Station 找到正確的URL。某些情況下，URL有限時下載，因此還需要 `RefreshDownloadLink()` 更新下載連結。

```php
interface IDownload {
    /*
     * GetDownloadLink()
     * @return {mixed} DownloadLink object or DownloadLink array
     */
    public function GetDownloadLink();
    /*
     * RefreshDownloadLink()
     * @param {DownloadLink} $dlink
     * @return {DownloadLink} DownloadLink object
     */
    public function RefreshDownloadLink($dlink);
}
```

`DownloadLink`已在php環境中定義如下，直接用`$link = new DownloadLink;`即可。
```php
final class DownloadLink {
    public $url = null;        // 真正的URL位址
    public $source = null;     // 原始的URL位址
    public $cookie = "";       // HTTP cookies，例如 "A=01;B=02;C=03"
    public $username = "";     // HTTP 基本驗證的 username
    public $password = "";     // HTTP 基本驗證的 password
    public $filename = "";     // 要儲存的檔名，等同於 "$base_name.$ext_name"
    public $filesize = 0;      // 檔案大小
    public $base_name = "";    // 檔名
    public $post_data = "";    // 用來傳 HTTP POST 的參數，例如 "a=1&b=2"
    public $ext_name = "";     // 副檔名
    public $is_folder = false; // 如果 FTP 資源是一個資料夾，就設為 true
    public $refresh_time = 0;  // 每隔多久要呼叫一次 RefreshDownloadLink，0代表無限久
    public $header = array();  // HTTP request headers，例如 "x-client-data: CI62yQ"
    static $CONTENT_TYPE = array(...)
    public function __construct($url = null, $header = null, $cookie = null);
    public function SetEncodeURL($encode_url);
```

## `IPostProcess`

有些工作是下載完成後才能執行，例如合併檔案、解壓縮。`IPostProcess` 可以輸入暫存的檔案清單，後處理再傳回新的檔案清單。

```php
interface IPostProcess {
    /*
     * PostProcess()
     * @param {string} $path download temp path
     * @param {array} $files temp file list
     * @param {string} $meta caller metadata
     * @return {array} file list in the $path
     */
    static public function PostProcess($path, $files, $meta);
}
```

## `Ajax`

需要爬網頁時，Download Station 提供了 `Ajax` class，模擬 `ExtJS`。`Ajax` 會自動儲存及更新 cookies，但開發者也可以用 `ResetCookie()` 來清除所有 cookies。如果想自己改寫 cookies，可以在呼叫 `Request()` 時提供 `$options`。

```php
final class Ajax {
    const AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.107 Safari/537.36";
    /*
     * Cleanup cookie value.
     */
    public function ResetCookie();
    /*
     * Emulate ExtJS ajax to do HTTP/FTP request.
     * If give non null $callback value will feedback
     * request header, response header, cookie value,
     * content data and last redirect url.
     *
     * @param {array} $options An object containing properties which are used as parameters to the request.
     * @param {callback} $callback The function to be called upon receipt of response.
     * @return {boolean}
     */
    public function Request($options, $callback = null);
}
```

### `$options` 的設定方式

* `body`: 預設為 true。設為 false 時會使用 HTTP HEAD method，只有部分網站支援。
* `post`: 預設為 false。設為 false 時使用 HTTP GET method；設為 true 時使用 HTTP POST method。
* `params`: 預設為 null。包含 POST/GET 的 params。
* `cookie`: 預設為 null。型態為 string array，例如 `array("A=01", "B=02", "C=03");`。
* `follow`: 預設為20。決定 URL redirect 可以發生幾次。
* `header`: 預設為 empty。代表自定義的 HTTP request header。
* `timeout`: 預設為20，最小值為1，最大值為20。決定幾秒會 timeout。

### `$callback` 的設定方式

```php
/*
 * @param {string} $request HTTP request header
 * @param {array} $header first received header will be last string element
 * @param {array} $cookie refer to options cookie value
 * @param {string} $body HTTP response data
 * @param {string} $effective_url last HTTP redirect URL
 */
function($request, $header, $cookie, $body, $effective_url);
```

# Summary

1. 先移動到`${DEFAULT_VOLUME}/.qpkg/DSv3/usr/sbin`目錄

2. 用 `./ds-addon -c <domain name> <class name>` 建立一個新的 addon，包含下列動作
    * 自動建立`addons/<domain name>`目錄
    * 自動建立`addons/<domain name>/addon.json`
    * 自動建立`addons/<domain name>/<domain name>.php`

3. 修改`addon.json`，使其符合需求 (假設要實作搜尋引擎，就要實作`ISearch`)

4. 實作`ISite`及`ISearch`的介面

5. `./ds-addon --search <addon> <keyword> [limit] [category]` 測試
    * 其中`<addon>`設定與`<domain name>`相同

6. `/usr/bin/openssl genrsa -out private.pem 1024` 產生 RSA Private Key

7. `/usr/bin/openssl rsa -in private.pem -out public.pem -outform PEM -pubout` 產生對應的 RSA Public Key

8. `./ds-addon-pack.sh private.pem public.pem addons/<domain name>/` 壓縮製作好的 Addon
