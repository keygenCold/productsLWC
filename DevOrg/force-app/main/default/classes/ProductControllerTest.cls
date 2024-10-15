@isTest
public class ProductControllerTest {
    
    @isTest
    static void testGetProductsByName() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Map<String, Object> result = ProductController.getProducts('Laptop', null, null);
        
        System.assertNotEquals(null, result, 'Expected products to be returned');
        System.assert(result.containsKey('products'), 'Expected products key in the result');
        List<Product2> products = (List<Product2>) result.get('products');
        System.assert(products.size() > 0, 'Expected at least one product to be returned');
    }
    
    @isTest
    static void testGetProductsByCategory() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Map<String, Object> result = ProductController.getProducts(null, 'electronics', null);
        
        System.assertNotEquals(null, result, 'Expected products to be returned');
        System.assert(result.containsKey('products'), 'Expected products key in the result');
        List<Product2> products = (List<Product2>) result.get('products');
        System.assert(products.size() > 0, 'Expected at least one product to be returned');
    }
    
    @isTest
    static void testGetProductsByBrand() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Map<String, Object> result = ProductController.getProducts(null, null, 'Samsung');
        
        System.assertNotEquals(null, result, 'Expected products to be returned');
        System.assert(result.containsKey('products'), 'Expected products key in the result');
        List<Product2> products = (List<Product2>) result.get('products');
        System.assert(products.size() > 0, 'Expected at least one product to be returned');
    }
    
    @isTest
    static void testFilterProducts() {
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 150; i++) {
            products.add(new Product2(
                Name = 'Product ' + i,
                Price__c = i * 100, 
                Stock__c = i + 1,
                DisplayUrl = 'https://example.com/image' + i + '.png',
                StockKeepingUnit = 'SKU' + i,
                ProductCode = 'CODE' + i,
                Brand__c = 'Brand ' + i,
                Rating__c = 4.5
            ));
        }
        
        List<Product2> filteredProducts = ProductController.filterProducts(products, 100, 10000);
        
        Decimal totalFilteredPrice = 0;
        for (Product2 product : filteredProducts) {
            totalFilteredPrice += product.Price__c;
        }
        System.assert(totalFilteredPrice <= 10000, 'Expected the total price to be less than or equal to 10,000.');
    }
    
    @isTest
    static void testProductInsertAndUpdate() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Map<String, Object> result = ProductController.getProducts('Laptop', null, null);
        
        List<Product2> products = [SELECT Id, Name, Price__c, Stock__c, DisplayUrl, StockKeepingUnit, ProductCode, Brand__c, Rating__c FROM Product2];
        System.assert(products.size() > 0, 'Expected at least one product to be inserted or updated');
        
        for (Product2 product : products) {
            System.assertNotEquals(null, product.Name, 'Product name should not be null');
            System.assertNotEquals(null, product.Price__c, 'Product price should not be null');
            System.assertNotEquals(null, product.Stock__c, 'Product stock should not be null');
            System.assertNotEquals(null, product.DisplayUrl, 'Product DisplayUrl should not be null');
            System.assertNotEquals(null, product.StockKeepingUnit, 'Product SKU should not be null');
            System.assertNotEquals(null, product.ProductCode, 'Product code should not be null');
            System.assertNotEquals(null, product.Brand__c, 'Product brand should not be null');
        }
    }
    
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            
            if (req.getEndpoint().contains('/auth/login')) {
                res.setStatusCode(200);
                res.setBody('{"accessToken": "mockedAccessToken"}');
            } else if (req.getEndpoint().contains('/products/search')) {
                res.setStatusCode(200);
                res.setBody('{"products": [' + 
                            '{"title": "Mocked Product 1", "price": 100, "stock": 5, "sku": "mockSKU1", "thumbnail": "mockImage1", "brand": "Samsung", "meta": {"barcode": "mockBarcode1"}},' + 
                            '{"title": "Mocked Product 2", "price": 150, "stock": 3, "sku": "mockSKU2", "thumbnail": "mockImage2", "brand": "Samsung", "meta": {"barcode": "mockBarcode2"}},' + 
                            '{"title": "Mocked Product 100", "price": 200, "stock": 2, "sku": "mockSKU100", "thumbnail": "mockImage100", "brand": "Samsung", "meta": {"barcode": "mockBarcode100"}}]}');
            } else if (req.getEndpoint().contains('/products/category')) {
                res.setStatusCode(200);
                res.setBody('{"products": [' + 
                            '{"title": "Mocked Category Product 1", "price": 200, "stock": 10, "sku": "mockSKU1", "thumbnail": "mockImage", "brand": "Apple", "meta": {"barcode": "mockBarcode"}}]}');
            } else {
                res.setStatusCode(200);
                res.setBody('{"products": [' + 
                            '{"title": "Mocked Product 1", "price": 150, "stock": 8, "sku": "mockSKU1", "thumbnail": "mockImage1", "brand": "Samsung", "meta": {"barcode": "mockBarcode1"}},' + 
                            '{"title": "Mocked Product 2", "price": 120, "stock": 12, "sku": "mockSKU2", "thumbnail": "mockImage2", "brand": "Samsung", "meta": {"barcode": "mockBarcode2"}}]}');
            }
            return res;
        }
    }
    
    private class MockFailedAuthResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(401);
            res.setBody('Unauthorized');
            return res;
        }
    }
}