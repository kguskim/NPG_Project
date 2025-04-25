package org.tensorflow.lite.examples.detection;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import java.text.SimpleDateFormat;
import java.util.Calendar;

public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main_page);

        TextView dateTxt = (TextView)findViewById((R.id.dateTxt));
        Button insertBtn = (Button)findViewById(R.id.insertBtn);

        Thread thread = new Thread() {
            @Override
            public void run() {
                while (!isInterrupted()) {
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            Calendar calendar= Calendar.getInstance(); //현재 시간을 가지고 있는 객체

                            SimpleDateFormat format =new SimpleDateFormat("E dd MM yyyy HH:mm:ss");
                            String time = format.format(calendar.getTime());

                            dateTxt.setText(time);
                        }
                    });
                    try {
                        Thread.sleep(1000); // 1000 ms = 1초
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                } // while
            } // run()
        }; // new Thread() { };

        thread.start();

        insertBtn.setOnClickListener(new View.OnClickListener(){
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(getApplicationContext(), InsertActivity.class);
                startActivity(intent);
            }
        });
    }
}