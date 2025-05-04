package org.tensorflow.lite.examples.detection;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import java.text.SimpleDateFormat;
import java.util.Calendar;

public class InsertPageActivity extends AppCompatActivity {
    private TextView ingredientName;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.insert_page);

        ingredientName = findViewById(R.id.ingredientName);
        Intent receiveIntent = getIntent();
        String[] ingredientsNames = receiveIntent.getStringArrayExtra("ingredients");
        String ppp = "";
        for (int i = 0; i < ingredientsNames.length; i++){
            Log.e("qsc", ingredientsNames[i]);
            ppp += ingredientsNames[i];
        }
        ingredientName.setText(ppp);
    }
}