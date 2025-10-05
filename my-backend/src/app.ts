import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import conversationsRouter from './routes/conversations';
import summariesRouter from './routes/summaries';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use('/api/conversations', conversationsRouter);
app.use('/api/summary', summariesRouter);

app.get('/health', (_req, res) => res.json({ ok: true }));

export default app;