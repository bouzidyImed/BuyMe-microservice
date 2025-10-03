package tn.iteam.catalogueservice.interfaces;

import tn.iteam.catalogueservice.models.Category;

import java.util.List;

public interface ICategory {
    Category getCategory(Long id);       // fetch one by id
    Category getCategoryName(String name);
    List<Category> getCategories();      // fetch all
    Category addCategory(Category category); // return saved category
    void removeCategory(Long categoryId);
    Category updateCategory(Long id, Category category); // optional for updates
}
