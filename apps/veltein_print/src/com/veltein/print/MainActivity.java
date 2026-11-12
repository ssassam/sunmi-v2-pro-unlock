package com.veltein.print;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Typeface;
import android.os.Bundle;
import android.os.IBinder;
import android.os.RemoteException;
import android.text.InputType;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import woyou.aidlservice.jiuiv5.IWoyouService;

public class MainActivity extends Activity {

    private IWoyouService printer;
    private EditText input;
    private CheckBox header;
    private EditText copies;

    private final ServiceConnection conn = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName name, IBinder service) {
            printer = IWoyouService.Stub.asInterface(service);
        }

        @Override
        public void onServiceDisconnected(ComponentName name) {
            printer = null;
        }
    };

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(36, 44, 36, 36);
        root.setBackgroundColor(Color.parseColor("#05140b"));

        TextView title = new TextView(this);
        title.setText("POS PRINTER");
        title.setTextColor(Color.parseColor("#00ff6a"));
        title.setTextSize(26f);
        title.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        root.addView(title);

        TextView hint = new TextView(this);
        hint.setText("Type what to print, then tap PRINT");
        hint.setTextColor(Color.parseColor("#7dffb0"));
        hint.setTextSize(13f);
        hint.setPadding(0, 4, 0, 16);
        root.addView(hint);

        input = new EditText(this);
        input.setHint("Enter text / receipt / form...");
        input.setInputType(InputType.TYPE_CLASS_TEXT
                | InputType.TYPE_TEXT_FLAG_MULTI_LINE
                | InputType.TYPE_TEXT_FLAG_CAP_SENTENCES);
        input.setMinLines(6);
        input.setGravity(Gravity.TOP | Gravity.START);
        input.setTextColor(Color.WHITE);
        input.setHintTextColor(Color.parseColor("#4a7a5e"));
        input.setBackgroundColor(Color.parseColor("#0b2416"));
        input.setPadding(20, 20, 20, 20);
        root.addView(input);

        header = new CheckBox(this);
        header.setText("Print VELTEIN logo header");
        header.setTextColor(Color.parseColor("#baffd4"));
        header.setChecked(false);
        root.addView(header);

        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        TextView cl = new TextView(this);
        cl.setText("Copies: ");
        cl.setTextColor(Color.parseColor("#baffd4"));
        cl.setTextSize(15f);
        cl.setPadding(0, 24, 8, 0);
        copies = new EditText(this);
        copies.setInputType(InputType.TYPE_CLASS_NUMBER);
        copies.setText("1");
        copies.setTextColor(Color.WHITE);
        copies.setWidth(120);
        copies.setBackgroundColor(Color.parseColor("#0b2416"));
        copies.setPadding(16, 12, 16, 12);
        row.addView(cl);
        row.addView(copies);
        root.addView(row);

        Button print = new Button(this);
        print.setText(">> PRINT <<");
        print.setTextColor(Color.BLACK);
        print.setTypeface(Typeface.MONOSPACE, Typeface.BOLD);
        print.setBackgroundColor(Color.parseColor("#00ff6a"));
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        lp.topMargin = 28;
        print.setLayoutParams(lp);
        print.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                doPrint();
            }
        });
        root.addView(print);

        Button feed = new Button(this);
        feed.setText("Feed paper");
        feed.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                feed();
            }
        });
        root.addView(feed);

        ScrollView sv = new ScrollView(this);
        sv.addView(root);
        setContentView(sv);

        Intent intent = new Intent();
        intent.setPackage("woyou.aidlservice.jiuiv5");
        intent.setAction("woyou.aidlservice.jiuiv5.IWoyouService");
        if (!bindService(intent, conn, Context.BIND_AUTO_CREATE)) {
            toast("Printer service not found");
        }
    }

    private Bitmap makeLogo() {
        int w = 384, h = 150;
        Bitmap bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888);
        Canvas c = new Canvas(bmp);
        c.drawColor(Color.WHITE);
        Paint border = new Paint(Paint.ANTI_ALIAS_FLAG);
        border.setStyle(Paint.Style.STROKE);
        border.setStrokeWidth(5);
        border.setColor(Color.BLACK);
        c.drawRect(8, 8, w - 8, h - 8, border);
        Paint t = new Paint(Paint.ANTI_ALIAS_FLAG);
        t.setColor(Color.BLACK);
        t.setTypeface(Typeface.create(Typeface.DEFAULT, Typeface.BOLD));
        t.setTextAlign(Paint.Align.CENTER);
        t.setTextSize(60f);
        c.drawText("VELTEIN", w / 2f, 82, t);
        t.setTextSize(22f);
        c.drawText("UNDER FAFOFI CORP", w / 2f, 120, t);
        return bmp;
    }

    private int copiesCount() {
        try {
            int n = Integer.parseInt(copies.getText().toString().trim());
            return Math.max(1, Math.min(10, n));
        } catch (Exception e) {
            return 1;
        }
    }

    private void doPrint() {
        if (printer == null) {
            toast("Printer not ready");
            return;
        }
        String text = input.getText().toString();
        if (text.trim().isEmpty() && !header.isChecked()) {
            toast("Nothing to print");
            return;
        }
        if (!text.endsWith("\n")) {
            text = text + "\n";
        }
        try {
            int n = copiesCount();
            for (int i = 0; i < n; i++) {
                printer.printerInit(null);
                if (header.isChecked()) {
                    printer.setAlignment(1, null);
                    printer.printBitmap(makeLogo(), null);
                    printer.printText("\n", null);
                }
                printer.setAlignment(0, null);
                printer.printText(text, null);
                printer.lineWrap(4, null);
            }
            toast("Printed (" + n + ")");
        } catch (RemoteException e) {
            toast("Print error: " + e.getMessage());
        }
    }

    private void feed() {
        if (printer == null) {
            return;
        }
        try {
            printer.lineWrap(4, null);
        } catch (RemoteException ignored) {
        }
    }

    private void toast(String m) {
        Toast.makeText(this, m, Toast.LENGTH_SHORT).show();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        try {
            unbindService(conn);
        } catch (Exception ignored) {
        }
    }
}
