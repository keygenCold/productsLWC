public with sharing class ProductController {
    private static final String API_BASE_URL = 'https://dummyjson.com';
    
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getProducts(String filterName, String filterCategory, String filterBrand) {
        String accessToken = authenticate();
        
        if (String.isEmpty(accessToken)) {
            throw new AuraHandledException('Authentication failed. No access token retrieved.');
        }
        
        List<Product2> productList = new List<Product2>();
        Integer totalStock = 0; 
        Decimal totalPrice = 0; 
        Integer productCount = 0; 
        
        if (String.isNotEmpty(filterName)) {
            productList = fetchProductsByName(filterName, accessToken);
        } else if (String.isNotEmpty(filterCategory)) {
            productList = fetchProductsByCategory(filterCategory, accessToken);
        } else {
            productList = fetchAllProducts(accessToken); 
        }
        
        if (String.isNotEmpty(filterBrand)) {
            productList = filterProductsByBrand(productList, filterBrand);
        }
        
        for (Product2 product : productList) {
            totalStock += (Integer) product.Stock__c;
            totalPrice += product.Price__c;
            productCount++;
        }
        
        if (productCount > 100 || totalPrice > 10000) {
            productList = filterProducts(productList, 100, 10000);
        }
        
        return new Map<String, Object> {
            'products' => productList,
                'totalStock' => totalStock
                };
                    }@TestVisible
    private static List<Product2> filterProducts(List<Product2> products, Integer maxCount, Decimal maxPrice) {
        List<Product2> filteredProducts = new List<Product2>();
        Decimal currentPrice = 0;
        
        for (Product2 product : products) {
            if (filteredProducts.size() < maxCount && currentPrice + product.Price__c <= maxPrice) {
                filteredProducts.add(product);
                currentPrice += product.Price__c;
            }
        }
        
        return filteredProducts;
    }

    @TestVisible
    private static String authenticate() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(API_BASE_URL + '/auth/login'); 
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        
        String requestBody = JSON.serialize(new Map<String, Object>{
            'username' => 'emilys',
                'password' => 'emilyspass',
                'expiresInMins' => 30 
                });
        req.setBody(requestBody);
        
        Http http = new Http();
        HttpResponse response = http.send(req);
        
        if (response.getStatusCode() == 200) {
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            return (String) jsonResponse.get('accessToken');
        } else {
            String errorMessage = 'Authentication failed: ' + response.getStatusCode() + ' - ' + response.getBody();
            System.debug('Throwing AuraHandledException with message: ' + errorMessage);
            throw new AuraHandledException(errorMessage);
        }
    }
    
    @TestVisible
    private static List<Product2> filterProductsByBrand(List<Product2> products, String filterBrand) {
        List<Product2> filteredByBrand = new List<Product2>();
        for (Product2 product : products) {
            if (product.Brand__c == filterBrand) {
                filteredByBrand.add(product);
            }
        }
        return filteredByBrand;
    }
    
    private static List<Product2> fetchProductsByName(String filterName, String accessToken) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(API_BASE_URL + '/products/search?q=' + EncodingUtil.urlEncode(filterName, 'UTF-8'));
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        
        Http http = new Http();
        HttpResponse response = http.send(req);
        
        if (response.getStatusCode() == 200) {
            return handleSuccessfulResponse(response.getBody());
        } else {
            throw new AuraHandledException('Failed to fetch products by name from API: ' + response.getStatusCode() + ' - ' + response.getBody());
        }
    }
    
    private static List<Product2> fetchProductsByCategory(String filterCategory, String accessToken) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(API_BASE_URL + '/products/category/' + EncodingUtil.urlEncode(filterCategory, 'UTF-8'));
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        
        Http http = new Http();
        HttpResponse response = http.send(req);
        
        if (response.getStatusCode() == 200) {
            return handleSuccessfulResponse(response.getBody());
        } else {
            throw new AuraHandledException('Failed to fetch products by category from API: ' + response.getStatusCode() + ' - ' + response.getBody());
        }
    }
    
    private static List<Product2> fetchAllProducts(String accessToken) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(API_BASE_URL + '/products');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        
        Http http = new Http();
        HttpResponse response = http.send(req);
        
        if (response.getStatusCode() == 200) {
            return handleSuccessfulResponse(response.getBody());
        } else {
            throw new AuraHandledException('Failed to fetch all products from API: ' + response.getStatusCode() + ' - ' + response.getBody());
        }
    }
    
    @TestVisible
    private static List<Product2> handleSuccessfulResponse(String responseBody) {
        List<Product2> productListToInsert = new List<Product2>();
        List<Product2> productListToUpdate = new List<Product2>();
        
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        List<Object> items = (List<Object>) jsonResponse.get('products');
        
        if (items != null) {
            for (Object itemObj : items) {
                Map<String, Object> item = (Map<String, Object>) itemObj;
                
                String productSKU = (String) item.get('sku');
                String thumbnail = (String) item.get('thumbnail');
                String barcode = (String) ((Map<String, Object>) item.get('meta')).get('barcode');
                Decimal productRating = (Decimal) item.get('rating');
                
                List<Product2> existingProducts = [SELECT Id, Name, Price__c, Stock__c, DisplayUrl, ProductCode, Brand__c, Rating__c FROM Product2 WHERE StockKeepingUnit = :productSKU LIMIT 1];
                
                if (existingProducts.isEmpty()) {
                    Product2 product = new Product2(
                        Name = (String) item.get('title'),
                        Description = (String) item.get('description'),
                        Price__c = (Decimal) item.get('price'),
                        Stock__c = (Integer) item.get('stock'),
                        DisplayUrl = thumbnail,
                        StockKeepingUnit = productSKU,
                        ProductCode = barcode,
                        Brand__c = (String) item.get('brand'),
                        Rating__c = productRating 
                    );
                    productListToInsert.add(product); 
                } else {
                    Product2 existingProduct = existingProducts[0];
                    existingProduct.Price__c = (Decimal) item.get('price');
                    existingProduct.Stock__c = (Integer) item.get('stock');
                    existingProduct.DisplayUrl = thumbnail;
                    existingProduct.ProductCode = barcode;
                    existingProduct.Brand__c = (String) item.get('brand');
                    existingProduct.Rating__c = productRating; 
                    productListToUpdate.add(existingProduct); 
                }
            }
        } else {
            throw new AuraHandledException('No products found in response.');
        }
        
        if (!productListToInsert.isEmpty()) {
            insert productListToInsert;
        }
        
        if (!productListToUpdate.isEmpty()) {
            update productListToUpdate;
        }
        
        return productListToInsert.isEmpty() ? productListToUpdate : productListToInsert;
    }
}