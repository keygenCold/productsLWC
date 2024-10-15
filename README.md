# productsLWC
**Components and classes used in lwc:**
 - productList.js
 - productList.html
 - productList.js-meta.xml
 - productList.css
 - ProductController.cls
 - ProductControllerTest.cls

Fields used in Product2 obj. to save products from API

| Field Label          | API Name              | Data Type           |
|----------------------|-----------------------|---------------------|
|   Created fields     |		       |		     |
| Brand                | Brand__c              | Text(70)            |
| Price                | Price__c              | Currency(10, 2)     |
| Rating               | Rating__c             | Number(10, 2)       |
| Stock 	       | Stock__c	       |Number(5, 0)  	     |
|		       |		       |		     |
|    Custom fields     |               	       |                     |
| Display URL          | DisplayUrl            | URL(1000)           |
| Product Name         | Name                  | Text(255)           |
| Product SKU          | StockKeepingUnit      | Text(180)           |
| Product Description  | Description           | Text Area(4000)     |

**Post-steps after deploy:**

**In Setup:**
-Go to Remote Site Settings 
	- Add a new remote site setting caled DummyJson
	- Remote Site Url : https://dummyjson.com
	
-Go to Security (Or search for CSP / Or even deploy my file on cspTrustedSites folder)
	- click on 'Trusted URLS'
	- Add a new Trusted Url with:
		- API : dummyJson 
		- URL : https://cdn.dummyjson.com 
		- CSP Context All
		- Check if img-src (images) is checked 
		- Check if Active = true
	(or the thumbnails of products will not load)

- Go to Profiles - System Administrator 
	-Custom Tab Settings and Product List should be Default On.
	- now the tab appears on Sales nav Bar
        - you just have to "add more items" and product List and it should be done.
