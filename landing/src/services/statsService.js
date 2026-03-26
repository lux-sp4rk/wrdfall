const LOCAL_STATS_KEY = 'word-loom-stats'

export const EMPTY_STATS = {
  high_score: 0,
  longest_word: '',
  max_wpm: 0,
  total_words: 0,
  total_tiles: 0,
  total_time: 0,
  session_history: [],
}

export class StatsService {
  constructor(supabaseClient) {
    this.supabase = supabaseClient
  }

  async getStats(userId = null) {
    if (this.supabase && userId) {
      try {
        const [profile, sessions] = await Promise.all([
          this._fetchProfile(userId),
          this._fetchSessions(userId),
        ])
        if (profile) return { ...EMPTY_STATS, ...profile, session_history: sessions }
      } catch (err) {
        console.warn('Supabase stats fetch failed, using localStorage fallback', err)
      }
    }
    return this._getLocalStats()
  }

  async getLeaderboard(limit = 20) {
    if (!this.supabase) return []
    try {
      const { data, error } = await this.supabase
        .from('leaderboards')
        .select('user_id, score, profiles(display_name)')
        .order('score', { ascending: false })
        .limit(limit)
      if (error) throw error
      // Add rank to each entry
      return (data ?? []).map((entry, index) => ({
        ...entry,
        rank: index + 1
      }))
    } catch (err) {
      console.warn('Leaderboard fetch failed', err)
      return []
    }
  }

  async resetStats() {
    localStorage.removeItem(LOCAL_STATS_KEY)
  }

  getShareText(stats) {
    return [
      'Word Loom Stats',
      '━━━━━━━━━━━━━━━',
      `High Score: ${stats.high_score}`,
      `Longest Word: ${stats.longest_word || '—'}`,
      `Max WPM: ${stats.max_wpm?.toFixed(1) ?? '0.0'}`,
      '',
      `Total Words: ${stats.total_words}`,
      `Total Tiles: ${stats.total_tiles}`,
      `Time Played: ${this.formatTime(stats.total_time ?? 0)}`,
    ].join('\n')
  }

  formatTime(seconds) {
    const h = Math.floor(seconds / 3600)
    const m = Math.floor((seconds % 3600) / 60)
    if (h > 0) return `${h}h ${m}m`
    if (m > 0) return `${m}m`
    return '<1m'
  }

  _getLocalStats() {
    try {
      const raw = localStorage.getItem(LOCAL_STATS_KEY)
      if (!raw) return { ...EMPTY_STATS }
      return { ...EMPTY_STATS, ...JSON.parse(raw) }
    } catch {
      return { ...EMPTY_STATS }
    }
  }

  async _fetchProfile(userId) {
    const { data, error } = await this.supabase
      .from('profiles')
      .select('high_score, longest_word, max_wpm, total_words, total_tiles, total_time')
      .eq('id', userId)
      .single()
    if (error) throw error
    return data
  }

  async _fetchSessions(userId) {
    const { data, error } = await this.supabase
      .from('sessions')
      .select('score, wpm, words_found, duration, timestamp')
      .eq('user_id', userId)
      .order('timestamp', { ascending: false })
      .limit(10)
    if (error) return []
    return data ?? []
  }
}
