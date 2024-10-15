import { LightningElement, track } from 'lwc'; 
import getProducts from '@salesforce/apex/ProductController.getProducts';

export default class ProductList extends LightningElement {
    @track products = [];
    @track filterName = '';
    @track filterCategory = '';
    @track filterBrand = ''; 
    @track isLoading = false;
    @track totalStock = 0;

    debounceTimeout;

    retrieveProducts() {
        this.isLoading = true;
        getProducts({
            filterName: this.filterName,
            filterCategory: this.filterCategory,
            filterBrand: this.filterBrand
        })
        .then(result => {
            this.products = result.products;
            this.totalStock = result.totalStock;
            this.isLoading = false;
        })
        .catch(error => {
            console.error('Error retrieving products:', error);
            this.isLoading = false;
        });
    }

    handleInputChange(event, filter) {
        this[filter] = event.target.value;
        clearTimeout(this.debounceTimeout);
        this.debounceTimeout = setTimeout(() => {
            this.retrieveProducts();
        }, 250); 
    }

    handleNameChange(event) {
        this.handleInputChange(event, 'filterName');
    }

    handleCategoryChange(event) {
        this.handleInputChange(event, 'filterCategory');
    }

    handleBrandChange(event) {
        this.handleInputChange(event, 'filterBrand');
    }

    connectedCallback() {
        this.retrieveProducts();
    }
}