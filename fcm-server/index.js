const express = require('express');
const admin = require('firebase-admin');
const bodyParser = require('body-parser');
const cors = require('cors');
const serviceAccount = require('./service_account_key.json');


if (!serviceAccount) {
  console.error(' ملف service_account_key.json غير موجود');
  process.exit(1);
}


try {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  console.log(' تم تهيئة Firebase Admin بنجاح');
} catch (error) {
  console.error(' فشل تهيئة Firebase Admin:', error);
  process.exit(1);
}

const app = express();


app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type']
}));

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));


app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'running',
    timestamp: new Date().toISOString(),
    firebaseAdminVersion: admin.SDK_VERSION
  });
});


app.post('/send-single', async (req, res) => {
  try {
    const { token, title, body, data } = req.body;

    
    if (!token || !title || !body) {
      return res.status(400).json({
        success: false,
        error: 'المعطيات المطلوبة: token, title, body'
      });
    }

    console.log(`📤 إرسال إشعار فردي إلى: ${token.substring(0, 6)}...`);

    const message = {
      token,
      notification: { title, body },
      data: data || {},
      android: {
        priority: 'high'
      },
      apns: {
        headers: {
          'apns-priority': '10'
        }
      }
    };

    const response = await admin.messaging().send(message);
    
    console.log(' تم الإرسال بنجاح - ID:', response);

    res.status(200).json({
      success: true,
      messageId: response
    });

  } catch (error) {
    console.error(' خطأ في الإرسال الفردي:', error);
    
    res.status(500).json({
      success: false,
      error: error.message,
      code: error.code || 'internal_error'
    });
  }
});


app.post('/send-multicast', async (req, res) => {
  try {
    const { tokens, title, body, data } = req.body;

    
    if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'يجب تقديم مصفوفة tokens صالحة'
      });
    }

    if (!title || !body) {
      return res.status(400).json({
        success: false,
        error: 'العنوان والمحتوى مطلوبان'
      });
    }

    
    const validTokens = tokens.filter(t => 
      t && typeof t === 'string' && t.length > 10
    );

    if (validTokens.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'لا توجد tokens صالحة للإرسال'
      });
    }

    console.log(` إرسال إشعار جماعي لـ ${validTokens.length} مستخدم`);

    const message = {
      tokens: validTokens,
      notification: { title, body },
      data: data || {},
      android: {
        priority: 'high'
      },
      apns: {
        headers: {
          'apns-priority': '10'
        }
      }
    };

    
    const batchSize = 500;
    const batches = [];
    
    for (let i = 0; i < validTokens.length; i += batchSize) {
      batches.push(validTokens.slice(i, i + batchSize));
    }

    const results = await Promise.all(
      batches.map(batchTokens => 
        admin.messaging().sendEachForMulticast({
          ...message,
          tokens: batchTokens
        })
      )
    );

    
    const summary = {
      totalSent: 0,
      totalFailed: 0,
      batches: results.map((result, index) => ({
        batch: index + 1,
        sent: result.successCount,
        failed: result.failureCount
      }))
    };

    results.forEach(result => {
      summary.totalSent += result.successCount;
      summary.totalFailed += result.failureCount;
    });

    console.log(` تم الإرسال: ${summary.totalSent} نجاح, ${summary.totalFailed} فشل`);

    res.status(200).json({
      success: true,
      ...summary
    });

  } catch (error) {
    console.error(' خطأ في الإرسال الجماعي:', error);
    
    res.status(500).json({
      success: false,
      error: error.message,
      code: error.code || 'internal_error'
    });
  }
});


app.use((err, req, res, next) => {
  console.error(' خطأ غير متوقع:', err.stack);
  res.status(500).json({
    success: false,
    error: 'حدث خطأ داخلي في الخادم'
  });
});


const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`\n الخادم يعمل على http://localhost:${PORT}`);
  console.log(' نهاية نقطة الإرسال الفردي: POST /send-single');
  console.log(' نهاية نقطة الإرسال الجماعي: POST /send-multicast');
  console.log(' نقطة التحقق من الصحة: GET /health\n');
});