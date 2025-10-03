package tn.iteam.catalogueservice.service;

import org.jvnet.hk2.annotations.Service;
import tn.iteam.catalogueservice.interfaces.ICategory;
import tn.iteam.catalogueservice.models.Category;
import tn.iteam.catalogueservice.repos.CategoryRepo;

import java.util.List;

@Service
public class CategoryService implements ICategory {

    private final CategoryRepo categoryRepo;

    public CategoryService(CategoryRepo categoryRepo) {
        this.categoryRepo = categoryRepo;
    }

    @Override
    public Category getCategory(Long id) {
        return null;
    }

    @Override
    public Category getCategoryName(String name) {
        return categoryRepo.getCategoriesByName(name);
    }

    @Override
    public List<Category> getCategories() {
        return categoryRepo.findAll();
    }

    @Override
    public Category addCategory(Category category) {
        return categoryRepo.save(category);
    }

    @Override
    public void removeCategory(Long categoryId) {

    }

    @Override
    public Category updateCategory(Long id, Category category) {
        return null;
    }
}
