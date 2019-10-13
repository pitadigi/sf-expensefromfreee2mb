public with sharing class pdQuota2MB {
    public static void sendQuota() {
        // 期間情報を取得する
        List<Period> p = [SELECT Id,StartDate,EndDate FROM Period];

        // 売上目標を取得する
        AggregateResult[] fq = [SELECT PeriodId,SUM(QuotaAmount) QuotaAmount FROM ForecastingQuota GROUP BY PeriodId];

        // 売上目標データを作成する
        String fqdata = '開始日,終了日,目標金額\r\n';
        for(Integer i=0 ; i<fq.size() ; i++) {
            fqdata += getStartDate(p, (Id)fq[i].get('PeriodId')) + ',';
            fqdata += getEndDate(p, (Id)fq[i].get('PeriodId')) + ',';
            fqdata += String.valueOf((Decimal)fq[i].get('QuotaAmount'));
            fqdata += '\r\n';
        }

        // MotionBoardに送信する
        sendForecast('売上目標', fqdata);

        // 売上目標スナップショップを実行する
        execSnapshot('売上目標');
    }

    /**
    * 期間情報から開始日を取得する
    */
    private static String getStartDate(List<Period> lstPeriod, Id periodId) {
        String ret;
        for(Period p : lstPeriod) {
            if (p.Id == periodId) {
                ret = String.valueOf(p.StartDate).replace('-', '/');
            }
        }

        return ret;
    }

    /**
    * 期間情報から終了日を取得する
    */
    private static String getEndDate(List<Period> lstPeriod, Id periodId) {
        String ret;
        for(Period p : lstPeriod) {
            if (p.Id == periodId) {
                ret = String.valueOf(p.EndDate).replace('-', '/');
            }
        }

        return ret;
    }

    /**
    * 売上予測データをMotionBoardに送信する
     */
    private static void sendForecast(String Type, String ForecastData) {
        // カスタムメタデータからMotionBoardに関する情報を取得する
        MotionBoard__mdt mb = [SELECT Url__c,TenantId__c,UserId__c,Password__c from MotionBoard__mdt WHERE DeveloperName='pitadigi' LIMIT 1];

        // 経費明細CSVをPOSTするリクエストを作成する
        HttpRequest req = new HttpRequest();
        String Boundary = '------------' + String.valueOf(DateTime.now().getTime());
        String Url = mb.Url__c + 'csv/put/shared/';
        Url += EncodingUtil.urlEncode('ぴたデジ', 'UTF-8');
        Url += '/' + EncodingUtil.urlEncode('売上', 'UTF-8');
        Url += '/' + EncodingUtil.urlEncode(Type + '.csv', 'UTF-8');
        req.setEndpoint(Url);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'multipart/form-data;boundary=' + Boundary);
        String Body = setParam(Boundary, 'tenant', mb.TenantId__c);
        Body += setParam(Boundary, 'id', mb.UserId__c);
        Body += setParam(Boundary, 'pw', mb.Password__c);
        Body += '--'+Boundary+'\r\nContent-Disposition: form-data; name="uploadFile"; filename="data.csv";\r\nContent-Type: text/csv\r\n\r\n' + 
        ForecastData + '\r\n--' + Boundary + '--';
        req.setBody(Body);
        req.setTimeout(10 * 1000);

        // MotionBoardにリクエストを送信する
        Http http = new Http();
        HttpResponse res = http.send(req);

        // エラーが返ってきたら例外をスローする
        if (res.getStatusCode() != 200) {
            throw new OtherException(getApiErrorMessage(res.getBody()));
        }
    }

    /**
    * MotionBoardにPOSTするためのパラメータを設定する
    */
    private static String setParam(String Boundary, String Param, String Value) {
        String ret = '--' + boundary+'\r\n'
        + 'Content-Disposition: form-data; name="' + Param + '"'
        + '\r\n\r\n' + Value + '\r\n';
        return ret;
    }

    /**
    * MotionBoardの売上予測スナップショットを実行する
    */
    private static void execSnapshot (String Type) {
        // カスタムメタデータからMotionBoardに関する情報を取得する
        MotionBoard__mdt mb = [SELECT Url__c,TenantId__c,UserId__c,Password__c from MotionBoard__mdt WHERE DeveloperName='pitadigi' LIMIT 1];

        // 経費明細スナップショット実行をPOSTするリクエストを作成する
        HttpRequest req = new HttpRequest();
        String Url = mb.Url__c + 'snapshot/task/exec/';
        Url += EncodingUtil.urlEncode(Type, 'UTF-8');
        req.setEndpoint(Url);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        String Body = 'tenant=' + EncodingUtil.urlEncode(mb.TenantId__c, 'UTF-8');
        Body += '&id=' + EncodingUtil.urlEncode(mb.UserId__c, 'UTF-8');
        Body += '&pw=' + EncodingUtil.urlEncode(mb.Password__c, 'UTF-8');
        req.setBody(Body);
        req.setTimeout(10 * 1000);

        // MotionBoardにリクエストを送信する
        Http http = new Http();
        HttpResponse res = http.send(req);

        // エラーが返ってきたら例外をスローする
        if (res.getStatusCode() != 200) {
            throw new OtherException(getApiErrorMessage(res.getBody()));
        }
    }

    /**
    * エラーメッセージを設定する
     */
    private static String getApiErrorMessage(String body) {
        System.debug(body);
        String errorMessage = 'Freee APIでエラーが発生しました\r\n';
        if (body != null && body.length() != 0) {
            Map<String, Object> mapError = (Map<String, Object>)JSON.deserializeUntyped(body);
            List<Object> lstError = (List<Object>)(mapError.get('errors'));
            for(Object mapErrorContent : lstError) {
                List<Object> lstMessage = (List<Object>)((Map<String, Object>)mapErrorContent).get('messages');
                for(Object message : lstMessage) {
                    errorMessage += message.toString() + '\r\n';
                }
            }
        }

        return errorMessage;
    }

    public virtual class BaseException extends Exception {}
    public class OtherException extends BaseException {}
}
