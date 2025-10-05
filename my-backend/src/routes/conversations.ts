// routes/conversations.ts
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
    const conversations = await prisma.conversation.findMany({
      where: { firebaseUid },
      orderBy: { updatedAt: 'desc' },
      select: {
        id: true,
        title: true,
        summary: true,
        createdAt: true,
        updatedAt: true,
      },
    });
    res.json(conversations);
  } catch (error) {
    console.error('GET /conversations error', error);
    res.status(500).json({ error: 'Erreur récupération des conversations' });
  }
});

router.post('/', async (req, res) => {
  const { firebaseUid, title } = req.body;
  if (!firebaseUid || typeof firebaseUid !== 'string') {
    return res.status(400).json({ error: 'firebaseUid requis' });
  }
  try {
    const conversation = await prisma.conversation.create({
      data: {
        firebaseUid,
        title: title ?? 'Conversation',
        summary: '',
      },
    });
    res.status(201).json({ conversationId: conversation.id });
  } catch (error) {
    console.error('POST /conversations error', error);
    res.status(500).json({ error: 'Erreur création conversation' });
  }
});

router.post('/:id/messages', async (req, res) => {
  const { id } = req.params;
  const { firebaseUid, content, isFromUser } = req.body;
  if (!firebaseUid || typeof firebaseUid !== 'string') {
    return res.status(400).json({ error: 'firebaseUid requis' });
  }
  if (content == null) {
    return res.status(400).json({ error: 'content requis' });
  }
  try {
    const convId = parseInt(id, 10);
    const conversation = await prisma.conversation.findUnique({ where: { id: convId } });
    if (!conversation) return res.status(404).json({ error: 'Conversation non trouvée' });
    if (conversation.firebaseUid !== firebaseUid) return res.status(403).json({ error: 'Non autorisé' });

    const message = await prisma.message.create({
      data: {
        conversationId: convId,
        content,
        isFromUser: !!isFromUser,
      },
    });

    await prisma.conversation.update({
      where: { id: convId },
      data: { updatedAt: new Date() },
    });

    res.status(201).json(message);
  } catch (error) {
    console.error('POST /conversations/:id/messages error', error);
    res.status(500).json({ error: 'Erreur ajout message' });
  }
});

router.put('/:id/summary', async (req, res) => {
  const { id } = req.params;
  const { firebaseUid, summary } = req.body;
  if (!firebaseUid || typeof firebaseUid !== 'string') {
    return res.status(400).json({ error: 'firebaseUid requis' });
  }
  try {
    const convId = parseInt(id, 10);
    const conversation = await prisma.conversation.findUnique({ where: { id: convId } });
    if (!conversation) return res.status(404).json({ error: 'Conversation non trouvée' });
    if (conversation.firebaseUid !== firebaseUid) return res.status(403).json({ error: 'Non autorisé' });

    const updated = await prisma.conversation.update({
      where: { id: convId },
      data: { summary },
    });
    res.json(updated);
  } catch (error) {
    console.error('PUT /conversations/:id/summary error', error);
    res.status(500).json({ error: 'Erreur mise à jour summary' });
  }
});

router.get('/:id', async (req, res) => {
  const { id } = req.params;
  const { firebaseUid } = req.query;
  if (!firebaseUid || typeof firebaseUid !== 'string') {
    return res.status(400).json({ error: 'firebaseUid requis' });
  }
  try {
    const convId = parseInt(id, 10);
    const conversation = await prisma.conversation.findUnique({
      where: { id: convId },
      include: { messages: { orderBy: { timestamp: 'asc' } } },
    });
    if (!conversation) return res.status(404).json({ error: 'Conversation non trouvée' });
    if (conversation.firebaseUid !== firebaseUid) return res.status(403).json({ error: 'Non autorisé' });
    res.json(conversation);
  } catch (error) {
    console.error('GET /conversations/:id error', error);
    res.status(500).json({ error: 'Erreur récupération' });
  }
});

router.delete('/:id', async (req, res) => {
  const { id } = req.params;
  const { firebaseUid } = req.query;
  if (!firebaseUid || typeof firebaseUid !== 'string') {
    return res.status(400).json({ error: 'firebaseUid requis' });
  }
  try {
    const convId = parseInt(id, 10);
    const conversation = await prisma.conversation.findUnique({ where: { id: convId } });
    if (!conversation) return res.status(404).json({ error: 'Conversation non trouvée' });
    if (conversation.firebaseUid !== firebaseUid) return res.status(403).json({ error: 'Non autorisé' });

    await prisma.conversation.delete({ where: { id: convId } });
    res.status(200).json({ success: true });
  } catch (error) {
    console.error('DELETE /conversations/:id error', error);
    res.status(500).json({ error: 'Erreur suppression' });
  }
});

export default router;