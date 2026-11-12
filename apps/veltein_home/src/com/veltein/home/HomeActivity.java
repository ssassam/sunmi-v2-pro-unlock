package com.veltein.home;

import android.app.Activity;
import android.app.WallpaperManager;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Typeface;
import android.os.Bundle;
import android.view.GestureDetector;
import android.view.MotionEvent;
import android.view.View;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.widget.Toast;

import java.util.Random;

public class HomeActivity extends Activity {

    private GestureDetector gestures;

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);

        try {
            WallpaperManager.getInstance(this).setBitmap(makeWallpaper());
        } catch (Exception ignored) {
        }

        WebView wv = new WebView(this);
        WebSettings s = wv.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        wv.setBackgroundColor(Color.BLACK);
        wv.loadUrl("file:///android_asset/veltein_home.html");

        gestures = new GestureDetector(this, new GestureDetector.SimpleOnGestureListener() {
            @Override
            public boolean onDoubleTap(MotionEvent e) {
                openApps();
                return true;
            }
        });
        wv.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View v, MotionEvent e) {
                gestures.onTouchEvent(e);
                return false;
            }
        });

        setContentView(wv);
        immersive();
    }

    private void openApps() {
        Toast.makeText(this, "Opening apps...", Toast.LENGTH_SHORT).show();
        Intent i = getPackageManager().getLaunchIntentForPackage("fr.neamar.kiss");
        if (i != null) {
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(i);
        }
    }

    private void immersive() {
        getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                        | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                        | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                        | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                        | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION);
    }

    @Override
    public void onWindowFocusChanged(boolean f) {
        super.onWindowFocusChanged(f);
        if (f) {
            immersive();
        }
    }

    @Override
    public void onBackPressed() {
        // stay on the home screen
    }

    private Bitmap makeWallpaper() {
        int w = 720, h = 1280;
        Bitmap bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888);
        Canvas c = new Canvas(bmp);
        c.drawColor(Color.BLACK);
        Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
        p.setTypeface(Typeface.MONOSPACE);
        p.setTextSize(22f);
        String ch = "VELTEINFAFOFI01<>/#*{}[]";
        Random r = new Random(7);
        for (int x = 0; x < w; x += 18) {
            int start = r.nextInt(h);
            for (int k = 0; k < 60; k++) {
                p.setColor(Color.parseColor("#00ff6a"));
                p.setAlpha(80 + r.nextInt(150));
                char cc = ch.charAt(r.nextInt(ch.length()));
                c.drawText(String.valueOf(cc), x, (start + k * 26) % h, p);
            }
        }
        Paint t = new Paint(Paint.ANTI_ALIAS_FLAG);
        t.setTextAlign(Paint.Align.CENTER);
        t.setColor(Color.parseColor("#baffd4"));
        t.setTypeface(Typeface.create(Typeface.MONOSPACE, Typeface.BOLD));
        t.setTextSize(72f);
        c.drawText("VELTEIN", w / 2f, h / 2f, t);
        t.setColor(Color.parseColor("#00ff6a"));
        t.setTextSize(26f);
        c.drawText("UNDER FAFOFI CORP", w / 2f, h / 2f + 50, t);
        return bmp;
    }
}
