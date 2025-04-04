CREATE TABLE user_list (
    user_id        VARCHAR(50) PRIMARY KEY,  
    user_email     VARCHAR(255) NOT NULL UNIQUE, 
    password       VARCHAR(255) NOT NULL    
);

CREATE TABLE category_list (
    ingredient_name VARCHAR(255) PRIMARY KEY, 
    category_name   VARCHAR(100) NOT NULL,    
    description     TEXT                     
);

CREATE TABLE area_list (
    area_id     INT PRIMARY KEY AUTO_INCREMENT,  
    area_name   VARCHAR(100) NOT NULL,           
    description TEXT                             
);

CREATE TABLE ingredient_list (
    ingredient_id   INT PRIMARY KEY AUTO_INCREMENT, 
    user_id        VARCHAR(50) NOT NULL,           
    ingredient_name VARCHAR(100) NOT NULL,         
    quantity       INT NOT NULL DEFAULT 1,         
    purchase_date  DATE NOT NULL,                 
    expiration_date DATE NOT NULL,                
    alias         VARCHAR(100),                   
    area_id       INT,                             
    image         VARCHAR(255),                   
    note          TEXT,                            
    FOREIGN KEY (user_id) REFERENCES user_list(user_id) ON DELETE CASCADE,
    FOREIGN KEY (area_id) REFERENCES area_list(area_id) ON DELETE SET NULL
);

CREATE TABLE recipe_type_id (
    recipe_type_id INT PRIMARY KEY AUTO_INCREMENT,  
    type_name      VARCHAR(100) NOT NULL,           
    description    TEXT                             
);

CREATE TABLE recipe_list (
    recipe_id     INT PRIMARY KEY AUTO_INCREMENT, 
    name          VARCHAR(255) NOT NULL,         
    cook_time     INT NOT NULL,                  
    cook_level    ENUM('1', '2', '3', '4', '5') NOT NULL, -- CHECK 대신 ENUM 사용
    recipe_type_id INT,                          
    image         VARCHAR(255),                  
    description   TEXT,                           
    FOREIGN KEY (recipe_type_id) REFERENCES recipe_type_id(recipe_type_id)
);

CREATE TABLE recipe_ingredient (
    recipe_id       INT NOT NULL,                
    ingredient_id   INT NOT NULL,                
    quantity        FLOAT NOT NULL,              
    gram           FLOAT,                        
    PRIMARY KEY (recipe_id, ingredient_id),
    FOREIGN KEY (recipe_id) REFERENCES recipe_list(recipe_id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES ingredient_list(ingredient_id) ON DELETE CASCADE
);

CREATE TABLE allergy_list (
    allergy_id       INT PRIMARY KEY AUTO_INCREMENT, 
    allergy_name     VARCHAR(100) NOT NULL,         
    allergy_ingredient_id INT NOT NULL,            
    FOREIGN KEY (allergy_ingredient_id) REFERENCES ingredient_list(ingredient_id) ON DELETE CASCADE
);
