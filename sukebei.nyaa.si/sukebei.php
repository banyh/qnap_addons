<?php
class sukebei implements ISite, ISearch {
    const SITE = "https://sukebei.nyaa.si/";
    private $url;

    public function __construct($url = null, $username = null, $password = null, $meta = null) {
        $this->url = $url;
    }

    static function UnitSize($unit) {
        switch (strtoupper($unit)) {
        case "KIB": return 1024;
        case "KB":  return 1024;
        case "MIB": return 1024 * 1024;
        case "MB": return 1024 * 1024;
        case "GIB": return 1024 * 1024 * 1024;
        case "GB": return 1024 * 1024 * 1024;
        case "TIB": return 1024 * 1024 * 1024 * 1024;
        case "TB": return 1024 * 1024 * 1024 * 1024;
        default: return 1;
        }
    }

    public function Search($keyword, $limit, $category) {
        $page = 1;
        $keyword = urlencode($keyword);

        $ajax = new Ajax();
        $found = array();
        $on_success = function ($request, $header, $cookie, $resp, $effective_url) use(&$page, &$found, &$limit) {
            preg_match_all('#.*?title="(?P<category>.*?)".*?title="(?P<title>.*?)".*?'.
                           'href="(?P<torrent>.*?)".*?href="(?P<magnet>.*?)".*?center">'.
                           '(?P<size>[0-9\.]+) +(?P<unit>.{3}).*?timestamp="(?P<timestamp>.*?)">'.
                           '(?P<datetime>.*?)</td>.*?(?P<seeders>[0-9]+).*?(?P<leechers>[0-9]+)#s',
                $resp,
                $result
            );

            if (!$result || ($len = count($result["title"])) == 0 ) {
                $page = false;
                return;
            }

            for ($i = 1 ; $i < $len ; ++$i) {
                $tlink = new SearchLink;

                $tlink->src           = "sukebei";
                $tlink->link          = $result["magnet"][$i];
                $tlink->name          = $result["title"][$i];
                $tlink->size          = ($result["size"][$i] + 0.0) * self::UnitSize($result["unit"][$i]);
                $tlink->seeds         = $result["seeders"][$i] + 0;
                $tlink->peers         = $result["leechers"][$i] + 0;
                $tlink->time          = DateTime::createFromFormat('Y-m-d H:i', $result["datetime"][$i]);
                $tlink->category      = $result["category"][$i];
                $tlink->enclosure_url = $tlink->link;

                $found []= $tlink;

                if (count($found) >= $limit) {
                    $page = false;
                    return;
                }
            }

            ++$page;
        };

        while ($page !== false && count($found) < $limit) {
            if (!$ajax->request(Array("url" => sukebei::SITE."?f=0&c=0_0&q=$keyword&p=$page"), $on_success)) {
                break;
            }
        }

        return $found;
    }
}
?>
