package org.tensorflow.lite.examples.detection;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import org.tensorflow.lite.examples.detection.R;

public class LoginActivity extends AppCompatActivity {
    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.login_page);

        Button loginBtn = (Button)findViewById(R.id.loginBtn);
        Button signUpBtn = (Button)findViewById(R.id.signUpBtn);

        loginBtn.setOnClickListener(new View.OnClickListener(){
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(getApplicationContext(), MainActivity.class);
                startActivity(intent);
            }
        });
        signUpBtn.setOnClickListener(new View.OnClickListener(){
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(getApplicationContext(), SignUpActivity.class);
                startActivity(intent);
            }
        });
    }
}
