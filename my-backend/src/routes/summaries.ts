import { Router } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const router = Router();


router.get('/', async (req, res) => {
  const { firebaseUid } = req.query;
  if (!firebaseUid || typeof firebaseUid !== 'string') {
    return res.status(400).json({ error: 'firebaseUid requis' });
  }
  try {
    const summaries = await prisma.summary.findMany({
      where: { firebaseUid },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        conversationId: true,
        context: true,
        summary: true,
        createdAt: true,
        updatedAt: true,
      },
    });
    res.json(summaries);
  } catch (error) {
    console.error('GET /summaries error', error);
    res.status(500).json({ error: 'Erreur récupération des summaries' });
  }
});

router.post('/', async (req, res) => {
  const { firebaseUid, conversationId, context, summary } = req.body;
  if (!firebaseUid || typeof firebaseUid !== 'string') {
    return res.status(400).json({ error: 'firebaseUid requis' });
  }
  if (!summary || typeof summary !== 'string') {
    return res.status(400).json({ error: 'summary requis' });
  }

  try {
    let convIdNum: number | null = null;
    if (conversationId !== undefined && conversationId !== null) {
      convIdNum = parseInt(String(conversationId), 10);
      if (Number.isNaN(convIdNum)) return res.status(400).json({ error: 'conversationId invalide' });

      const conv = await prisma.conversation.findUnique({ where: { id: convIdNum } });
      if (!conv) return res.status(404).json({ error: 'Conversation non trouvée' });
      if (conv.firebaseUid !== firebaseUid) return res.status(403).json({ error: 'Non autorisé pour cette conversation' });
    }

    let existing: any = null;
    if (convIdNum != null) {
      existing = await prisma.summary.findFirst({
        where: { conversationId: convIdNum, firebaseUid }
      });
    } else {

      existing = null;
    }

    if (existing) {
      const updated = await prisma.summary.update({
        where: { id: existing.id },
        data: {
          summary,
          context: context !== undefined ? context : existing.context,
        },
      });
      return res.status(200).json(updated); 
    } else {
      const created = await prisma.summary.create({
        data: {
          conversationId: convIdNum,
          firebaseUid,
          context: context ?? null,
          summary,
        },
      });
      return res.status(201).json(created);
    }
  } catch (error) {
    console.error('POST /summaries error', error);
    res.status(500).json({ error: 'Erreur création summary' });
  }
});

router.get('/:id', async (req, res) => {
  const { id } = req.params;
  const { firebaseUid } = req.query;
  if (!firebaseUid || typeof firebaseUid !== 'string') {
    return res.status(400).json({ error: 'firebaseUid requis' });
  }

  try {
    const summary = await prisma.summary.findUnique({
      where: { id },
      include: { conversation: true },
    });
    if (!summary) return res.status(404).json({ error: 'Summary non trouvé' });
    if (summary.firebaseUid !== firebaseUid) return res.status(403).json({ error: 'Non autorisé' });

    res.json(summary);
  } catch (error) {
    console.error('GET /summaries/:id error', error);
    res.status(500).json({ error: 'Erreur récupération summary' });
  }
});


router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const { firebaseUid, summary, context } = req.body;
  if (!firebaseUid || typeof firebaseUid !== 'string') {
    return res.status(400).json({ error: 'firebaseUid requis' });
  }
  if ((summary !== undefined && typeof summary !== 'string') || (context !== undefined && typeof context !== 'string')) {
    return res.status(400).json({ error: 'Champs invalides' });
  }

  try {
    const existing = await prisma.summary.findUnique({ where: { id } });
    if (!existing) return res.status(404).json({ error: 'Summary non trouvé' });
    if (existing.firebaseUid !== firebaseUid) return res.status(403).json({ error: 'Non autorisé' });

    const updated = await prisma.summary.update({
      where: { id },
      data: {
        summary: summary !== undefined ? summary : existing.summary,
        context: context !== undefined ? context : existing.context,
      },
    });

    res.json(updated);
  } catch (error) {
    console.error('PUT /summaries/:id error', error);
    res.status(500).json({ error: 'Erreur mise à jour summary' });
  }
});

router.delete('/:id', async (req, res) => {
  const { id } = req.params;
  const { firebaseUid } = req.query;
  if (!firebaseUid || typeof firebaseUid !== 'string') {
    return res.status(400).json({ error: 'firebaseUid requis' });
  }

  try {
    const existing = await prisma.summary.findUnique({ where: { id } });
    if (!existing) return res.status(404).json({ error: 'Summary non trouvé' });
    if (existing.firebaseUid !== firebaseUid) return res.status(403).json({ error: 'Non autorisé' });

    await prisma.summary.delete({ where: { id } });
    res.status(200).json({ success: true });
  } catch (error) {
    console.error('DELETE /summaries/:id error', error);
    res.status(500).json({ error: 'Erreur suppression summary' });
  }
});

export default router;